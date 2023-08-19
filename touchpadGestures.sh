#!/usr/bin/env bash

################################################################################
# Script name:  touchpadGestures.sh
# Description:  This script automates installation and configuration of touchpad
#               gestures in Linux Mint. It pulls libinput-gestures repository
#               from GitHub, installs necessary dependencies and finally extends
#               default functionality with macOS-like gesture configuration.
# Usage:        ./touchpadGestures.sh
# Author:       Tomasz Targiel
# Version:      1.0
# Date:         28.09.2022
################################################################################

# Add $USER to input group
sudo gpasswd -a $USER input
[ $? -eq 0 ] && echo "Success!" || echo "Fail!"

# Install necessary dependencies
echo -e "\nInstalling necessary dependencies..."
sudo apt update
# Set AUTO_ACCEPT variable to '-y' - that way apt will not ask you to confirm installation
AUTO_ACCEPT="-y"
sudo apt install git libinput-tools wmctrl xdotool "$AUTO_ACCEPT"
[ $? -eq 0 ] && echo "Success!" || echo "Fail!"

# Clone libinput-gestures repository
cd ~/
echo -e "\nSpeaking to GitHub..."
git clone https://github.com/bulletmark/libinput-gestures.git
[ $? -eq 0 ] && echo "Success!" || echo "Fail!"
cd libinput-gestures/

# Install libinput-gestures and remove intallation remains
echo -e "\nInstalling libinput-gestures..."
sudo make install
[ $? -eq 0 ] && echo "Success!" || echo "Fail!"
cd ../
rm -rf libinput-gestures/

# Enable libinput-gestures autostart and try to start application
echo -e "\nEnabling libinput-gestures to start automatically at login ..."
echo "Starting libinput-gestures..."
libinput-gestures-setup autostart start
echo "If libinput-gestures failed to start, you might want to restart your computer"

# Duplicate default configuration and append macOS-like gesture configuration to it
echo -e "\nPersonalising libinput-gestures configuration..."
cp /etc/libinput-gestures.conf /home/$USER/.config/libinput-gestures.conf
[ $? -eq 0 ] && echo "Successfully duplicated default configuration!" || echo "Failed to duplicate default configuration!"
# Dbus signals below have been discovered using D-Feet (d-feet) application. Session Bus address can be found using 'echo $DBUS_SESSION_BUS_ADDRESS'
echo -e "\ngesture swipe up 3 dbus-send --print-reply --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.switchWorkspaceDown\ngesture swipe down 3 dbus-send --print-reply --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.switchWorkspaceUp\ngesture swipe left 3 dbus-send --print-reply --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.switchWorkspaceRight\ngesture swipe right 3 dbus-send --print-reply --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.switchWorkspaceLeft" >> /home/$USER/.config/libinput-gestures.conf
[ $? -eq 0 ] && echo "Successfully added macOS-like gestures to configuration file!" || echo "Failed to add macOS-like gestures to configuration file!"