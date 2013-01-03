#!/bin/bash
# apt-add-repository is not installed on all system and is part of
# python-software-properties package.
sudo apt-get install -y python-software-properties

# Add salt PPA key and create PPA file.
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E27C0A6
sudo apt-add-repository -y ppa:saltstack/salt

sudo apt-get update
sudo apt-get install -y salt-minion
sudo sed -i 's/#master: salt/master: salt.chevah.com/' /etc/salt/minion
sudo service salt-minion restart
