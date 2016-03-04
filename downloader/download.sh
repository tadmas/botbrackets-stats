#!/bin/bash

set -C

###############################################################################
# Generate all the temporary files used by the script.

teamlist_file=$(mktemp -t teamlist.$$.XXXXXXXXXX)
gamelist_file=$(mktemp -t gamelist.$$.XXXXXXXXXX)
gamenums_file=$(mktemp -t gamenums.$$.XXXXXXXXXX)
gameurls_file=$(mktemp -t gameurls.$$.XXXXXXXXXX)
kenpom_raw_file=$(mktemp -t kenpomraw.$$.XXXXXXXXXX)
kenpom_tidy_file=$(mktemp -t kenpomtidy.$$.XXXXXXXXXX)
kenpom_sql_file=$(mktemp -t kenpomsql.$$.XXXXXXXXXX)

function cleanup {
  rm "$teamlist_file"
  rm "$gamelist_file"
  rm "$gamenums_file"
  rm "$gameurls_file"
  rm "$kenpom_raw_file"
  rm "$kenpom_tidy_file"
  rm "$kenpom_sql_file"
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
  -f   Fixup file for game stats.
  -b   Blacklist file; lists game numbers to not download.

PROCESSING FLAGS:
  -a   Process all files, not just missing ones. (Files are not re-downloaded.)
  -P   Process only; do not download any game files.
  -k   Download new KenPom data (used to check W/L records).
  -g   Download the specified games by number.  List is comma delimited.

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
	if [[ -n $BLACKLIST_FILE ]]; then
		# can use gameurls as a temporary file since we're about to overwrite it anyway
		sort "$gamenums_file" >| "$gameurls_file"
		comm -23 "$gameurls_file" <(sort "$BLACKLIST_FILE") >| "$gamenums_file"
	fi
	sed "s/^/http:\/\/stats.ncaa.org\/game\/period_stats\//" "$gamenums_file" >| "$gameurls_file"
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

function gamelistarg_to_gamenums {
	cp /dev/null "$gamenums_file"

	# http://stackoverflow.com/a/918931/3750
	IFS=',' read -ra GAMES <<< "$GAME_LIST"
	for game_number in "${GAMES[@]}"; do
		echo $game_number >> "$gamenums_file"
	done
}

###############################################################################
# Download functions

function wget_stats {
	wget $WGET_OPTIONS --user-agent="Mozilla/5.0" $@
}

function download_team_games {
	status_message "Downloading game list from $1"
	wget_stats -O "$gamelist_file" "$1"
	status_message "Game list downloaded."

	sleep 3

	gamelist_to_gamenums
	gamenums_to_gameurls

	if [ -s "$gameurls_file" ]; then
		status_message "Downloading missing games:"
		status_output_file "$gamenums_file"
		wget_stats -nc -t 0 -w 10 --random-wait -i "$gameurls_file" -P "$STATS_DIR/original"
	else
		status_message "The games for this team are all already downloaded."
	fi
}

function download_all_teams {
	status_message "Downloading team list..."
	wget_stats -O "$teamlist_file" "http://stats.ncaa.org/team/inst_team_list?academic_year=$STATS_YEAR&conf_id=-1&division=1&sport_code=MBB"

	sed "s/</\n</g" "$teamlist_file" | \
	sed -n "s/<a href=.\/team\/\([0-9][0-9]*\/[0-9][0-9]*\).*$/http:\/\/stats.ncaa.org\/team\/\1/p" | \
	while read team_url; do
		download_team_games "$team_url"
	done
}

function download_game_list {
	status_message "Downloading specified games..."
	
	gamelistarg_to_gamenums
	gamenums_to_gameurls

	if [ -s "$gameurls_file" ]; then
		status_message "Downloading missing games:"
		status_output_file "$gamenums_file"
		wget_stats -nc -t 0 -w 10 --random-wait -i "$gameurls_file" -P "$STATS_DIR/original"
	else
		status_message "The specified games have all already been downloaded."
	fi
}

function download_kenpom {
	status_message "Downloading KenPom file..."
	wget $WGET_OPTIONS -O "$kenpom_raw_file" "http://kenpom.com"
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
			-e "s/[\<]note/note/g" \
			-e "s/[\<]Liacouras/Liacouras/g" \
			-e "s/[\<]INTRUST/INTRUST/g" \
			-e "s/[\<]Strahan/Strahan/g" \
			-e "s/[\<]Cameron/Cameron/g" \
			-e "s/[\<]Stroh/Stroh/g" \
			-e "s/[\<]Carnesecca/Carnesecca/g" \
			-e "s/[\<]University/University/g" \
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

function import_games_to_db {
	status_message "Importing games into DB..."
	mysql -u bbstatsdownload "-p$MYSQL_PASSWORD" bbstats < "$SCRIPT_DIR/resetdb.sql"
	dir_to_gamenums sql
	while read game_number; do
		mysql -u bbstatsdownload "-p$MYSQL_PASSWORD" bbstats < "$STATS_DIR/sql/$game_number"
	done < "$gamenums_file"

	if [[ ! -z $FIXUP_FILE ]]; then
		status_message "Running fixup file..."
		mysql -u bbstatsdownload "-p$MYSQL_PASSWORD" bbstats < "$FIXUP_FILE"
	fi

	status_message "Doing DB post-processing..."
	mysql -u bbstatsdownload "-p$MYSQL_PASSWORD" bbstats < "$SCRIPT_DIR/process.sql"
}

function create_json_file {
	status_message "Creating JSON file..."
	php \
		-d mysqli.default_host=localhost \
		-d mysqli.default_user=bbstatsdownload \
		-d mysqli.default_pw="$MYSQL_PASSWORD" \
		"$SCRIPT_DIR/json.php" >| "$STATS_DIR/stats.json"
}

function process_kenpom_file {
	status_message "Running tidy on KenPom file..."
	tidy -b -n -q -asxml -o "$kenpom_tidy_file" "$kenpom_raw_file" 2>/dev/null >/dev/null
	status_message "Running XSL on KenPom file..."
	xsltproc -o "$kenpom_sql_file" --novalid --nonet "$SCRIPT_DIR/kenpom_sql.xsl" "$kenpom_tidy_file"
	status_message "Importing KenPom data into database..."
	mysql -u bbstatsdownload "-p$MYSQL_PASSWORD" bbstats < "$kenpom_sql_file"
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
PROCESS_KENPOM=0
MYSQL_PASSWORD=
FIXUP_FILE=
BLACKLIST_FILE=
GAME_LIST=
while getopts ":O:y:p:f:b:aPkg:hqQ" OPTION; do
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
		f)
			FIXUP_FILE="$OPTARG"
			;;
		b)
			BLACKLIST_FILE="$OPTARG"
			;;
		a)
			PROCESS_MISSING=0
			;;
		P)
			SKIP_DOWNLOAD=1
			;;
		k)
			PROCESS_KENPOM=1
			;;
		g)
			GAME_LIST="$OPTARG"
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
	if [[ -z $GAME_LIST ]]; then
		download_all_teams
	else
		download_game_list
	fi
fi

if [[ $PROCESS_KENPOM = 1 ]]; then
	download_kenpom
	process_kenpom_file
fi

clean_games
tidy_games
transform_games
import_games_to_db
create_json_file

status_message "Done."
