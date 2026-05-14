#!/command/with-contenv bash
if [ -z "$LAT" ] || [ -z "$LON" ] || [ -z "$FEEDER_ID" ]; then
    echo "Error: LAT, LON and FEEDER_ID environment variables must be set."
    exit 1
fi

if [ -z "$RECEIVER_HOST" ] || [ -z "$RECEIVER_PORT" ] || [ -z "$RECEIVER_TYPE" ]; then
    echo "Error: RECEIVER_HOST, RECEIVER_PORT, and RECEIVER_TYPE environment variables must be set."
    exit 1
fi

echo $FEEDER_ID > /var/cache/piaware/feeder_id

cat <<EOF > /var/cache/piaware/location
$LAT
$LON
EOF

cat <<EOF > /var/cache/piaware/location.env
PIAWARE_LAT="$LAT"
PIAWARE_LON="$LON"
PIAWARE_DUMP1090_LOCATION_OPTIONS="--lat $LAT --lon $LON"
EOF

cat <<EOF > /etc/piaware.conf
allow-auto-updates=no
allow-manual-updates=no
allow-mlat=yes
mlat-results=yes
receiver-host=$RECEIVER_HOST
receiver-port=$RECEIVER_PORT
receiver-type=$RECEIVER_TYPE
mlat-results-format=beast,connect,$MLAT_BEAST_HOST:$MLAT_BEAST_PORT beast,listen,30105 ext_basestation,listen,30106
use-gpsd=no
EOF

if [ "$DEBUG" = "true" ]; then
    echo piaware.conf contents:
    cat /etc/piaware.conf
fi

# If the volume has been populated by dump1090-fa and mounted, link it to the expected location
if [ -d "/usr/share/skyaware/html" ]; then
    echo "Linking /usr/share/skyaware/html to /var/www/html/skyaware"
    ln -s /usr/share/skyaware/html /var/www/html/skyaware
else
    echo "No /usr/share/skyaware/html found. Skipping link to /var/www/html/skyaware"
fi

if ! grep -q "$SKYAWARE_URL" /etc/lighttpd/conf-enabled/50-piaware.conf; then
    if [ -n "$SKYAWARE_URL" ]; then
        cat <<EOF >> /etc/lighttpd/conf-enabled/50-piaware.conf
\$HTTP["url"] =~ "^/skyaware/" {
    url.redirect = ( "^/skyaware/(.*)" => "$SKYAWARE_URL/\$1" )
}
EOF

        lighttpd -t -f $CONFIG_PATH
        if [ $? -ne 0 ]; then
            echo "Error: lighttpd configuration test failed. Please check the configuration."
            exit 1
        fi
    else
        echo "SKYAWARE_URL is not set. Skipping the addition of the redirect rule."
    fi
else
    echo "Redirect for /skyaware/ already exists in /etc/lighttpd/conf-enabled/50-piaware.conf"
fi

echo Starting piaware
if [ "$DEBUG" = "true" ]; then
    /usr/bin/piaware -p /run/piaware/piaware.pid -plainlog -statusfile /run/piaware/status.json -debug
else
    /usr/bin/piaware -p /run/piaware/piaware.pid -plainlog -statusfile /run/piaware/status.json
fi