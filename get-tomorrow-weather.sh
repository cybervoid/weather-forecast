#!/usr/bin/env bash

set -euo pipefail

# Weather forecast URL
URL="https://forecast.weather.gov/MapClick.php?CityName=Rye+Brook&state=NY&site=OKX&textField1=41.0304&textField2=-73.6866&e=0"

# Get tomorrow's day name (e.g., "Friday")
# Support both BSD date (macOS) and GNU/BusyBox date (Linux)
if date -v+1d "+%A" &>/dev/null; then
    # BSD date (macOS)
    DAY=$(date -v+1d "+%A")
else
    # GNU/BusyBox date (Linux) - add 86400 seconds (1 day)
    TOMORROW=$(date -d "@$(($(date +%s) + 86400))" "+%A" 2>/dev/null)
    if [ -z "$TOMORROW" ]; then
        # Fallback for very minimal BusyBox: use current day + 1
        TODAY_NUM=$(date +%u)  # 1=Monday, 7=Sunday
        TOMORROW_NUM=$(( (TODAY_NUM % 7) + 1 ))
        case $TOMORROW_NUM in
            1) DAY="Monday" ;;
            2) DAY="Tuesday" ;;
            3) DAY="Wednesday" ;;
            4) DAY="Thursday" ;;
            5) DAY="Friday" ;;
            6) DAY="Saturday" ;;
            7) DAY="Sunday" ;;
        esac
    else
        DAY="$TOMORROW"
    fi
fi
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
