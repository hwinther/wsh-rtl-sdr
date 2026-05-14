#!/command/with-contenv bash
cat <<EOF > /etc/fr24feed.ini
receiver="$RECEIVER_TYPE"
fr24key="$FR24_KEY"
host="$RECEIVER_HOST:$RECEIVER_PORT"
bs="no"
raw="no"
mlat="no"
mlat-without-gps="no"
EOF

echo Starting fr24feed
/opt/fr24feed/fr24feed
