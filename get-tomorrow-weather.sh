#!/usr/bin/env bash

set -euo pipefail

# Weather forecast URL
URL="https://forecast.weather.gov/MapClick.php?CityName=Rye+Brook&state=NY&site=OKX&textField1=41.0304&textField2=-73.6866&e=0"

# Get tomorrow's day name (e.g., "Friday")
DAY=$(date -v+1d "+%A")
NIGHT="${DAY} Night"

# Fetch and parse the weather forecast
HTML=$(curl -sS -L -f --max-time 15 --retry 2 "$URL") || {
    echo "Error: Failed to fetch weather data" >&2
    exit 1
}

# Extract forecasts for tomorrow (both day and night)
# First, split forecast blocks into separate lines
echo "$HTML" | sed 's/<div class="row[^"]*"><div class="col-sm-2 forecast-label">/\n&/g' | \
    grep 'forecast-label' | \
    grep -E "<b>(${DAY}|${NIGHT})</b>" | \
    sed -E 's/.*forecast-text">([^<]+)<\/div>.*/\1/' | \
    sed 's/  */ /g' | \
    sed 's/^ *//;s/ *$//'

# Check if we got any results
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Error: Failed to parse weather data" >&2
    exit 1
fi
