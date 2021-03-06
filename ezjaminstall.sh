set -eo pipefail
JAMULUS_FILE=jamulus_headless_3.8.0_ubuntu_amd64.deb
JAMULUS_URL=https://github.com/jamulussoftware/jamulus/releases/download/r3_8_0/$JAMULUS_FILE
NUM_STEPS=5

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists sudo && test "$(whoami)" = root
then
  echo "Step 0/$NUM_STEPS - Install sudo"
  apt update --allow-releaseinfo-change -y
  apt install sudo -y
fi

echo "Step 1/$NUM_STEPS - Download Jamulus"
wget -O"$JAMULUS_FILE" "$JAMULUS_URL"

echo "Step 2/$NUM_STEPS - Update system"
sudo apt update --allow-releaseinfo-change -y

echo "Step 3/$NUM_STEPS - Install Jamulus"
sudo apt install ./jamulus_headless_3.8.0_ubuntu_amd64.deb -y

echo "Step 4/$NUM_STEPS - Configure Jamulus"

if ! test -e /etc/jamulus-server-info
then
SERVER_NAME=ezjam
if command -v openssl
then
SERVER_NAME=ezjam-"$(openssl rand -hex 2)"
fi
echo "$SERVER_NAME;Unspecified;0" | sudo tee /etc/jamulus-server-info
fi

if ! test -e /etc/jamulus-max-users
then
echo '10' | sudo tee /etc/jamulus-max-users
fi

if ! test -e /etc/jamulus-welcome-message
then
echo 'Configured by ez-jamulus-server<br>https://github.com/dtinth/ez-jamulus-server' | sudo tee /etc/jamulus-welcome-message
fi

if ! test -e /etc/jamulus-directory-server
then
echo 'anygenre1.jamulus.io:22124' | sudo tee /etc/jamulus-directory-server
fi

sudo mkdir -p /var/run/jamulus
sudo chown jamulus:nogroup /var/run/jamulus

echo '#!/bin/bash -e
if test -e /etc/jamulus-private
then
exec /usr/bin/jamulus-headless -s -n -w /etc/jamulus-welcome-message -u "$(cat /etc/jamulus-max-users)" -T -m /var/run/jamulus/status.html
else
exec /usr/bin/jamulus-headless -s -n -w /etc/jamulus-welcome-message -u "$(cat /etc/jamulus-max-users)" -T -m /var/run/jamulus/status.html --serverinfo "$(cat /etc/jamulus-server-info)" --directoryserver "$(cat /etc/jamulus-directory-server)"
fi
' | sudo tee /usr/bin/ez-jam-server

sudo chmod +x /usr/bin/ez-jam-server

sudo sed -i 's!ExecStart=.*!ExecStart=/bin/sh -c '\''exec /usr/bin/ez-jam-server'\''!' /lib/systemd/system/jamulus-headless.service

echo "Step 5/$NUM_STEPS - Start"
sudo systemctl daemon-reload
sudo systemctl restart jamulus-headless

echo "Finished. Your server name is \"$(cat /etc/jamulus-server-info | cut --fields=1 --delimiter=';')\""
