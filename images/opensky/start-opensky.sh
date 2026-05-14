#!/command/with-contenv bash
mkdir -p /etc/openskyd/conf.d
cat <<EOF > /etc/openskyd/conf.d/10-opensky.conf
[GPS]
Latitude=$LAT
Longitude=$LON
Altitude=$ALT

[DEVICE]
Type=$OPENSKY_DEVICE_TYPE

[IDENT]
Username=$OPENSKY_USERNAME

[INPUT]
Host=$RECEIVER_HOST
Port=$RECEIVER_PORT
EOF

if [ -z "$OPENSKY_SERIAL" ]
then
  echo ""
  echo "WARNING: OPENSKY_SERIAL environment variable was not set!"
  echo "Please make sure you note down the serial generated."
  echo "Pass the key as environment var OPENSKY_SERIAL on next launch!"
  echo ""
else
  cat <<EOF > /etc/openskyd/conf.d/05-serial.conf
[Device]
serial = $OPENSKY_SERIAL
EOF
fi

echo Starting opensky daemon
/usr/bin/openskyd-dump1090