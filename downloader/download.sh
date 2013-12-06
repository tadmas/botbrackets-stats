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
	mkdir -p "$STATS_DIR/cleaned"
	mkdir -p "$STATS_DIR/tidy"
	mkdir -p "$STATS_DIR/sql"
}

###############################################################################
# Usage

function usage {
cat << EOF
This script downloads and processes NCAA men's basketball game files.

PARAMETERS:
  -O   Output directory for game files.
  -y   Academic year of statistics to download.
  -p   Password to the stats database.

PROCESSING FLAGS:
  -a   Process all files, not just missing ones. (Files are not re-downloaded.)
  -P   Process only; do not download any game files.
  -k   Download new KenPom data (used to check W/L records).

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
# File methods

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

function dir_to_gamenums {
	ls -1 "$STATS_DIR/$1" >| "$gamenums_file"
}

function missing_to_gamenums {
	cp /dev/null "$gamenums_file"

	ls -1 "$STATS_DIR/$2" | while read game_number; do
		if [ ! -f "$STATS_DIR/$1/$game_number" ]; then
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
	sed -n "s/<a href=.\/team\/index\/\([0-9][0-9]*[?]org_id=[0-9]*\).*$/http:\/\/stats.ncaa.org\/team\/index\/\1/p" | \
	while read team_url; do
		download_team_games "$team_url"
	done
}

###############################################################################
# Processing functions

function clean_games {
	if [[ $PROCESS_MISSING = 1 ]]; then
		status_message "Cleaning missing games..."
		missing_to_gamenums cleaned original
		status_output_file "$gamenums_file"
	else
		status_message "Cleaning..."
		dir_to_gamenums original
	fi

	while read game_number; do
		sed \
			-e "s/\<R\>//g" \
			-e "s/\<O\>//g" \
			-e "s/\<rules//g" \
			-e "s/[\<]Liacouras/Liacouras/g" \
			-e "s/[\<]INTRUST/INTRUST/g" \
		"$STATS_DIR/original/$game_number" >| "$STATS_DIR/cleaned/$game_number"
	done < "$gamenums_file"
}

function tidy_games {
	if [[ $PROCESS_MISSING = 1 ]]; then
		status_message "Running tidy on missing games..."
		missing_to_gamenums tidy cleaned
		status_output_file "$gamenums_file"
	else
		status_message "Running tidy..."
		dir_to_gamenums cleaned
	fi

	while read game_number; do
		tidy -b -n -q -w 8000 -asxml -o "$STATS_DIR/tidy/$game_number" "$STATS_DIR/cleaned/$game_number" 2>&1 >/dev/null | grep -v "Warning: "
	done < "$gamenums_file"
}

function transform_games {
	if [[ $PROCESS_MISSING = 1 ]]; then
		status_message "Running XSL on missing games..."
		missing_to_gamenums sql tidy
		status_output_file "$gamenums_file"
	else
		status_message "Running XSL..."
		dir_to_gamenums tidy
	fi

	while read game_number; do
		xsltproc -o "$STATS_DIR/sql/$game_number" --stringparam GAMENO "$game_number" --novalid --nonet "$SCRIPT_DIR/game_sql.xsl" "$STATS_DIR/tidy/$game_number"
	done < "$gamenums_file"
}

###############################################################################
# MAIN SCRIPT

SCRIPT_DIR="$(dirname "$0")"
STATS_YEAR=
STATS_DIR=
WGET_OPTIONS=
QUIET_MODE=0
SKIP_DOWNLOAD=0
PROCESS_MISSING=1
MYSQL_PASSWORD=
while getopts ":O:y:p:aPkhqQ" OPTION; do
	case $OPTION in
		O)
			STATS_DIR="$OPTARG"
			;;
		y)
			STATS_YEAR=$OPTARG
			;;
		p)
			MYSQL_PASSWORD="$OPTARG"
			;;
		a)
			PROCESS_MISSING=0
			;;
		P)
			SKIP_DOWNLOAD=1
			;;
		k)
			echo "Option -k not implemented yet." >&2
			exit 1
			;;
		h)
			usage
			exit
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

if [[ -z $STATS_DIR ]]; then
	echo "Option -O is required." >&2
	exit 1
fi

if [[ -z $STATS_YEAR ]] && [[ $SKIP_DOWNLOAD = 0 ]]; then
	echo "Option -y is required." >&2
	exit 1
fi

if [[ -z $MYSQL_PASSWORD ]]; then
	echo "The database password (option -p) is required." >&2
	exit 1
fi

create_output_directories 

if [[ $SKIP_DOWNLOAD = 0 ]]; then
	download_all_teams
fi

clean_games
tidy_games
transform_games
