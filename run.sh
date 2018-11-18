#! /bin/bash

# Download last nights CO2 data.

cd "$(dirname "$0")"
set -eu

# Define NETATMO_ vars not stored in Git.
. .login

# Location of login cookies
COOKIE_DIR=cookies
RAW_DIR=raw
SVG_DIR=plots

getCSV() {
    TOKEN="$1"
    begin="$2"
    end="$3"
    outfile="$4"
    moduleId="$5"
    curl 'http://app.netatmo.net/api/getmeasurecsv' \
         -d "access_token=$TOKEN" \
         -d "device_id=$NETATMO_BIG_ID" \
         -d 'type=Temperature,Humidity,CO2,Noise,Pressure' \
         -d "module_id=$moduleId" \
         -d 'scale=max' \
         -d 'format=csv' \
         -d "date_begin=$begin" \
         -d "date_end=$end" \
         -s \
         -o "$outfile"
    if grep '"error"' "$outfile" ; then
        echo 'Deleting cookies'
        rm -rf $COOKIE_DIR
        exit 1
    fi
}

extractAuth() {
    cookieFile=$1
    grep netatmocomaccess_token "$cookieFile" | cut -f7
}

# Based on
# https://www.michaelmiklis.de/export-netatmo-weather-station-data-to-csv-excel/
auth() {
    URL_LOGIN="https://auth.netatmo.com/en-US/access/login"
    SESSION_COOKIE="$COOKIE_DIR/session.cookie"
    AUTH_COOKIE="$COOKIE_DIR/auth.cookie"

    if [ -r $SESSION_COOKIE -a -r $AUTH_COOKIE ] ; then
        extractAuth $SESSION_COOKIE
        return
    fi

    mkdir -p $COOKIE_DIR

    # first we need to get a valid session cookie
    curl $URL_LOGIN -s -c $AUTH_COOKIE > /dev/null

    # then extract the ID from the authentication cookie
    SESS_ID="$(grep netatmocomci_csrf_cookie_na $AUTH_COOKIE | cut -f7)"

    # and now we can login using cookie, id, user and password
    curl $URL_LOGIN \
         -d "ci_csrf_netatmo=$SESS_ID" \
         -d "mail=$NETATMO_USER" \
         -d "pass=$NETATMO_PASS" \
         -d "log_submit=LOGIN" \
         -b $AUTH_COOKIE \
         -c $SESSION_COOKIE \
         -s \
         > /dev/null

    # Wait for token to become valid. (Avoids 500 error)
    sleep 1
    extractAuth $SESSION_COOKIE
}

lastNight() {
    token=$1
    ymd=$(   date --date="yesterday 13:00" '+%Y-%m-%d')
    begin=$( date --date="yesterday 18:00" '+%s')
    end=$(   date --date="today     09:00" '+%s')

    mkdir -p $RAW_DIR
    mkdir -p $SVG_DIR

    small="$RAW_DIR/$ymd-small.csv"
    big="$RAW_DIR/$ymd-big.csv"
    getCSV "$token" "$begin" "$end" "$small" "$NETATMO_SML_ID"
    getCSV "$token" "$begin" "$end" "$big"   "$NETATMO_BIG_ID"
    gnuplot -e "ymd='$ymd'" plot.gp
}

token=$(auth)
lastNight "$token"
