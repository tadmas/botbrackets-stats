botbrackets-stats
=================

Stats scraper for botbrackets.com

Overview
--------

This scraper downloads and processes NCAA basketball game data for use on botbrackets.com.
The basic process is as follows:

1. Download the game files from the NCAA stats website.
2. Fix up any invalid HTML in the file by calling a "cleaner" function (basically, calls to sed).
3. Run HTML Tidy to convert the messy HTML into a well-formed XML document.
4. Run an XSL transform on the XML document to turn it into a series of SQL insert statements.
5. Execute the generated SQL statements against a mysql database.
6. Generate team and game summary information using the data in the mysql database.
7. Execute a script that reads the summary data and produces a JSON file for use by the website.

Along with this process, a simple website is included to allow checking for errors and anomalies
in the downloaded data.

Setup
-----

1. Ensure you have the dependencies installed.
   
        apt-get install apache2 mysql-server mysql-client php5 php5-mysql tidy xsltproc

2. Set up the bbstats database.

        mysql -p < database/schema.sql

3. Create the script and website login accounts.

        mysql -p < database/users.sql

4. Load the preset data.

        mysql -p bbstats < database/kenpom_mapping.sql

5. Set up the site in Apache to point to the website directory.
6. Update the site settings to specify the mysql connection properties.

        <Location />
            php_value mysqli.default_host localhost
            php_value mysqli.default_user bbstatswebsite
            php_value mysqli.default_pw   ******
        </Location>

Usage
-----

Periodically run the download script (downloader/download.sh) to download game files and load
them into the mysql database.  The basic format of the download command line is:

    downloader/download.sh [FLAGS] -O (output-directory) -y (year) -p (password) -f (fixup-file)
    
The flags that control the download are:

* `-P` - Don't download any files; just run the processing steps.  Useful after adjusting the
  fixup file.

* `-k` - Process a new set of data from kenpom.com.  This is done as a check against W/L records
  to look for missing games.

* `-g "12345,67890,..."` - Download only the specific game numbers instead of checking for all
  missing games.  This is primarily useful late in the season when looking for specific missed
  games without having to wait for the whole scraper to run.

* `-a` - Similar to `-P`, except it reprocesses all files fully instead of only processing missing
  files.  This is useful after making changes to the processing code itself.

* `-q` - Suppress all output, except for errors.  This can be useful when running the script as
  a cron job.

* `-Q` - Same as `-q`, except it also shows status messages.  This can be useful when running the
  script using nohup.

Dealing with errors
-------------------

Some of the downloaded data will be funky.  There are two mechanisms for dealing with manual data fixes:

* Fixup file - The downloader takes a parameter for a sql script to manually run when it is loading the
  downloaded game data.  Typical fixes in this file will be: setting the game time when the incoming
  time is unparseable, updating bad stats values, or fixing team names.

* Manual verification table - The bbstats database has a table called `ManualStatsVerification` that
  allows marking a game as manually checked so that it doesn't show up in the reports on the website.
  The most common use for this is to handle the points check when a team scores in their own basket:
  that counts as points but not towards FGM, so the numbers don't add up.

Other processing errors typically need to be addressed in the download script itself.  These generally
fall into two categories:

* Cleaner - The cleaner process handles malformed HTML in the file.  (One popular mistake is replacing
  parentheses with angle brackets.)  This requires adding a new case to the script.

* Transform - Occasionally, stray characters will make their way into the resulting sql script.  The
  XSL transform needs to be updated with an appropriate call to `translate` to remove the offending
  character.
