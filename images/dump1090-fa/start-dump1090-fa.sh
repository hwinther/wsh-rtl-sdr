#!/command/with-contenv bash
# https://github.com/edgeofspace/dump1090-fa/blob/master/dump1090.c
# --net-ri-port <ports>    TCP raw input listen ports  (default: 30001)
# --net-ro-port <ports>    TCP raw output listen ports (default: 30002)
# --net-sbs-port <ports>   TCP BaseStation output listen ports (default: 30003)
# --net-bi-port <ports>    TCP Beast input listen ports  (default: 30004,30104)
# --net-bo-port <ports>    TCP Beast output listen ports (default: 30005)

REDIRECT='$HTTP["url"] =~ "^/$" {
    url.redirect = ("/" => "/tar1090/")
}'
CONFIG_PATH="/etc/lighttpd/lighttpd.conf"
if ! grep -q "$REDIRECT" $CONFIG_PATH; then
    echo "Adding redirect rule to $CONFIG_PATH"
    cat <<EOF >> $CONFIG_PATH
$REDIRECT
EOF

    lighttpd -t -f $CONFIG_PATH
    if [ $? -ne 0 ]; then
        echo "Error: lighttpd configuration test failed. Please check the configuration."
        exit 1
    fi

    echo "Restarting lighttpd to apply changes"
    s6-rc -d change lighttpd
    s6-rc -u change lighttpd
else
    echo "Redirect for /tar1090/ already exists in $CONFIG_PATH"
fi

echo Dump1090-fa version:
/usr/bin/dump1090-fa --version

echo Starting dump1090-fa

/usr/bin/dump1090-fa \
    --device-type $DEVICE_TYPE --device-index $DEVICE_INDEX --gain 60 --adaptive-range \
    --wisdom /etc/dump1090-fa/wisdom.local \
    --fix --lat $LAT --lon $LON --max-range 360 \
    --net-ro-port 30002 --net-sbs-port 30003 --net-bi-port 30004,30104 --net-bo-port 30005 \
    --json-location-accuracy 1 --write-json /run/dump1090-fa \
    $EXTRA_ARGS
