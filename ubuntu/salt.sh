#!/bin/bash
# Get Ubuntu code name.
release_code=`lsb_release -cs`

# Add salt PPA key and create PPA file.
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E27C0A6
echo "deb http://ppa.launchpad.net/saltstack/salt/ubuntu $release_code main " > \
    /etc/apt/sources.list.d/saltstack-salt-${release_code}.list

sudo apt-get update
sudo apt-get install -y salt-minion
sudo sed -i 's/#master: salt/master: salt.chevah.com/' /etc/salt/minion
sudo service salt-minion restart
