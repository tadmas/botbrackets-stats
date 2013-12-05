#!/bin/bash

set -C

###############################################################################
# Generate all the temporary files used by the script.

teamlist_file=$(mktemp -t teamlist.$$.XXXXXXXXXX)
gamelist_file=$(mktemp -t gamelist.$$.XXXXXXXXXX)
gamenums_file=$(mktemp -t gamenums.$$.XXXXXXXXXX)
gameurls_file=$(mktemp -t gameurls.$$.XXXXXXXXXX)

function cleanup {
  rm "$teamlist_file"
  rm "$gamelist_file"
  rm "$gamenums_file"
  rm "$gameurls_file"
}
trap cleanup EXIT

###############################################################################
# Output directories

function create_output_directories {
	mkdir -p "$STATS_DIR/original"
}

###############################################################################
# Usage

function usage {
cat << EOF
This script downloads and processes NCAA men's basketball game files.

PARAMETERS:
  -O   Output directory for game files.
  -y   Academic year of statistics to download.

MISC OPTIONS:
  -h   Show this message.
  -q   Suppress output except for errors.
  -Q   Suppress output except for status messages and errors.
EOF
}

###############################################################################
# Output methods

function status_message {
	if [[ $QUIET_MODE = 0 ]]; then
		echo $1
	fi
}

function status_output_file {
	if [[ $QUIET_MODE = 0 ]]; then
		cat $1
	fi
}

###############################################################################
# Processing methods

function gamenums_to_gameurls {
	sed "s/^/http:\/\/stats.ncaa.org\/game\/index\//" "$gamenums_file" >| "$gameurls_file"
}

function gamelist_to_gamenums {
	cp /dev/null "$gamenums_file"

	sed "s/</\n</g" "$gamelist_file" | \
	sed -n "s/<a href=.\/game\/index\/\([0-9]*\)\?.*$/\1/p" | \
	while read game_number; do
		if [ ! -f "$STATS_DIR/original/$game_number" ]; then
			echo $game_number >> "$gamenums_file"
		fi
	done
}

###############################################################################
# Download functions

function download_team_games {
	status_message "Downloading game list from $1"
	wget $WGET_OPTIONS -O "$gamelist_file" "$1"
	status_message "Game list downloaded."

	sleep 3

	gamelist_to_gamenums
	gamenums_to_gameurls

	if [ -s "$gameurls_file" ]; then
		status_message "Downloading missing games:"
		status_output_file "$gamenums_file"
		wget $WGET_OPTIONS -nc -t 0 -w 10 --random-wait -i "$gameurls_file" -P "$STATS_DIR/original"
	else
		status_message "The games for this team are all already downloaded."
	fi
}

function download_all_teams {
	status_message "Downloading team list..."
	wget $WGET_OPTIONS -O "$teamlist_file" "http://stats.ncaa.org/team/inst_team_list?academic_year=$STATS_YEAR&conf_id=-1&division=1&sport_code=MBB"

	sed "s/</\n</g" "$teamlist_file" | \
	sed -n "s/<a href=.\/team\/index\/\(11540[?]org_id=[0-9]*\).*$/http:\/\/stats.ncaa.org\/team\/index\/\1/p" | \
	while read team_url; do
		download_team_games "$team_url"
	done
}

###############################################################################
# MAIN SCRIPT

STATS_YEAR=
STATS_DIR=
WGET_OPTIONS=
QUIET_MODE=0
while getopts ":hy:O:qQ" OPTION; do
	case $OPTION in
		h)
			usage
			exit
			;;
		y)
			STATS_YEAR=$OPTARG
			;;
		O)
			STATS_DIR="$OPTARG"
			;;
		q)
			WGET_OPTIONS+=" -q"
			QUIET_MODE=1
			;;
		Q)
			WGET_OPTIONS+=" -q"
			;;
		?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done

# These are checked separately since eventually this script will be able to do things other than
# downloading files, so the year parameter might be optional.

if [[ -z $STATS_DIR ]]; then
	echo "Option -O is required." >&2
	exit 1
fi

if [[ -z $STATS_YEAR ]]; then
	echo "Option -y is required." >&2
	exit 1
fi

create_output_directories 
download_all_teams
