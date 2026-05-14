#!/command/with-contenv bash

# lazy way to wait for the configuration file to have been modified by start-adsbexchange.sh
sleep 10

while true; do
    /bin/bash /usr/local/share/adsbexchange-stats/json-status
    sleep 30
done