set -eo pipefail
JAMULUS_FILE=jamulus_headless_3.8.0_ubuntu_amd64.deb
JAMULUS_URL=https://github.com/jamulussoftware/jamulus/releases/download/r3_8_0/$JAMULUS_FILE
NUM_STEPS=5

echo "Step 1/$NUM_STEPS - Download Jamulus"
wget -O"$JAMULUS_FILE" "$JAMULUS_URL"

echo "Step 2/$NUM_STEPS - Update system"
sudo apt update --allow-releaseinfo-change -y

echo "Step 3/$NUM_STEPS - Install Jamulus"
sudo apt install ./jamulus_headless_3.8.0_ubuntu_amd64.deb -y

echo "Step 4/$NUM_STEPS - Configure Jamulus"

if ! test -e /etc/jamulus-server-info
then
echo 'ezjam;Somewhere;0' | sudo tee /etc/jamulus-server-info
fi

if ! test -e /etc/jamulus-max-users
then
echo '10' | sudo tee /etc/jamulus-max-users
fi

if ! test -e /etc/jamulus-welcome-message
then
echo 'Configured by ez-jamulus-server' | sudo tee /etc/jamulus-welcome-message
fi

if ! test -e /etc/jamulus-directory-server
then
echo 'anygenre1.jamulus.io:22124' | sudo tee /etc/jamulus-directory-server
fi

echo '#!/bin/bash -e
if test -e /etc/jamulus-private
then
exec /usr/bin/jamulus-headless -s -n -w /etc/jamulus-welcome-message -u "$(cat /etc/jamulus-max-users)" -T -m /tmp/jamulus-status.html
else
exec /usr/bin/jamulus-headless -s -n -w /etc/jamulus-welcome-message -u "$(cat /etc/jamulus-max-users)" -T -m /tmp/jamulus-status.html --serverinfo "$(cat /etc/jamulus-server-info)" --directoryserver "$(cat /etc/jamulus-directory-server)"
fi
' | sudo tee /usr/bin/ez-jam-server

sudo chmod +x /usr/bin/ez-jam-server

sudo sed -i 's!ExecStart=.*!ExecStart=/bin/sh -c '\''exec /usr/bin/ez-jam-server'\''!' /lib/systemd/system/jamulus-headless.service

echo "Step 5/$NUM_STEPS - Start"
sudo systemctl daemon-reload
sudo systemctl restart jamulus-headless

echo "Finished."
