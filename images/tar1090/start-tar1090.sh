#!/command/with-contenv bash
if [ -n "$AISCATCHER_SERVER" ]; then
    sed -i "s|// aiscatcher_server = \"http://192.168.1.113:8100\"; // update with your server address|aiscatcher_server = \"$AISCATCHER_SERVER\";|" /usr/local/share/tar1090/html/config.js
    echo "Updated aiscatcher_server to $AISCATCHER_SERVER"
else
    echo "AISCATCHER_SERVER is not set. Skipping update for aiscatcher_server."
fi

if [ -n "$AISCATCHER_REFRESH" ]; then
    sed -i "s|// aiscatcher_refresh = 15; // refresh interval in seconds|aiscatcher_refresh = $AISCATCHER_REFRESH;|" /usr/local/share/tar1090/html/config.js
    echo "Updated aiscatcher_refresh to $AISCATCHER_REFRESH"
else
    echo "AISCATCHER_REFRESH is not set. Skipping update for aiscatcher_refresh."
fi

if [ -n "$HEYWHATSTHAT_ID" ]; then
    echo "Fetching HeyWhatsThat data for ID $HEYWHATSTHAT_ID"
    /usr/local/share/tar1090/getupintheair.sh $HEYWHATSTHAT_ID
fi

echo Starting tar1090
/usr/local/share/tar1090/tar1090.sh /run/tar1090 /run/dump1090-fa
