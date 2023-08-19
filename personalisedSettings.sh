#!/usr/bin/env bash

################################################################################
# Script name:  personalisedSettings.sh
# Description:  This script automates applying personalised OS settings in Linux
#               Mint. It changes background image, animation speed, theme,
#               enables zoom, disables recent files, changes screensaver prefs,
#               Alt-Tab style, positioning shortcuts, enables tap to click,
#               changes sleep timeout, sounds, sound levels, enables calendar
#               to use custom date format, shows hidden files, battery %, sets
#               Xed's theme, creates many useful aliases and enables FireWall.
# Usage:        ./personalisedSettings.sh
# Author:       Tomasz Targiel
# Version:      1.0
# Date:         28.09.2022
################################################################################

# GSettings schemas, keys and values have been discovered using dconf Editor (dconf-editor) application

echo "Appearance:"

gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/linuxmint/sele_ring_green.jpg'
echo -e "\tBackgrounds > Images: Background image is now set to LINUX MINT SELE RING GREEN\n"

gsettings set org.cinnamon window-effect-speed 2
echo -e "\tEffects: Window animation speed is now set to FASTER\n"

gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y-Dark'
echo -e "\tThemes > Themes: Icons are now set to MINT-Y-DARK"
gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
echo -e "\tThemes > Themes: Applications are now set to MINT-Y-DARK"
gsettings set org.cinnamon.desktop.interface cursor-theme 'DMZ-Black'
echo -e "\tThemes > Themes: Mouse Pointer is now set to DMZ-BLACK"
gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
echo -e "\tThemes > Themes: Icons are now set to MINT-Y-DARK\n"

echo "Preferences:"

gsettings set org.cinnamon.desktop.a11y.applications screen-magnifier-enabled true
echo -e "\tAccessibility > Visual: Enable zoom is now set to TRUE\n"

gsettings set org.cinnamon.desktop.privacy remember-recent-files false
echo -e "\tPrivacy: Remember recently accessed files is now set to FALSE\n"

gsettings set org.cinnamon.desktop.session idle-delay 120
echo -e "\tScreensaver: Delay before starting the screensaver is now set to 2 MINUTES\n"

gsettings set org.cinnamon alttab-switcher-style 'coverflow'
echo -e "\tWindows > Alt-Tab: Alt-Tab switcher style is now set to COVERFLOW (3D)\n"

echo "Hardware:"

gsettings set org.cinnamon.desktop.keybindings.wm move-to-center "['<Primary><Alt>c']"
echo -e "\tKeyboard > Shortcuts > Windows > Positioning: Center window in screen is now set to CTRL+ALT+C\n"

gsettings set org.cinnamon.desktop.peripherals.touchpad tap-to-click true
echo -e "\tMouse and Touchpad > Touchpad: Tap to click is now set to ENABLED\n"

gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 600
echo -e "\tPower Management > Power: Sleep timeout display when on AC is now set to 10 MINUTES"

gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 300
echo -e "\tPower Management > Power: Sleep timeout display when on battery is now set to 5 MINUTES\n"

# Find input device index corresponding to Internal Microphone and set MIC variable to it (first grep does print line containing 'alsa-input' and one line before that, second grep prints everything in between 'index: ' and end of the line '$')
MIC=$(pacmd list-sources | grep -B 1 'alsa_input' | grep -o -P '(?<=index: ).*(?=$)')
# Find maximal volume of the device and set MAX_VOL variable to it (sed prints everything between 'alsa_input' and 'analog-input-mic', grep prints everything in between 'volume steps: ' and end of the line '$')
MAX_VOL=$(pacmd list-sources | sed -n '/alsa_input/,/analog-input-mic/p' | grep -o -P '(?<=volume steps: ).*(?=$)')
# Set MIC_VOL variable to result of the equation (bc calculates 25% of maximal volume and rounds it to the nearest number '+ 0.5 ) / 1')
MIC_VOL=$(echo "(($MAX_VOL * 0.25) + 0.5) / 1" | bc)
pacmd set-source-volume ${MIC} ${MIC_VOL}
echo -e "\tSound > Input: Internal Microphone volume is now set to 25%"
gsettings set org.cinnamon.sounds switch-enabled false
echo -e "\tSound > Sounds: Switching workspace is now set to FALSE"
gsettings set org.cinnamon.desktop.sound volume-sound-enabled false
echo -e "\tSound > Sounds: Changing the sound volume is now set to FALSE"
gsettings set org.cinnamon.desktop.sound maximum-volume 150
echo -e "\tSound > Sounds: Maximum volume is now set to 150%\n"

# Find .json configuration file of Calendar and set CALENDAR variable to it's path
CALENDAR=$(find /home/$USER/.cinnamon/configs/calendar@cinnamon.org/ -name '*.json')
# Replace third occurence of line containing '"value"'
awk '/"value":.*/{c++;if(c==3){sub("\"value\":.*","\"value\": true")}}1' $CALENDAR > ~/temp.json && mv ~/temp.json $CALENDAR
# Replace fourth occurence of line containing '"value"'
awk '/"value":.*/{c++;if(c==4){sub("\"value\":.*","\"value\": \"    %d/%m/%Y  |  %H:%M    \"")}}1' $CALENDAR > ~/temp.json && mv ~/temp.json $CALENDAR
echo -e "Calendar is now set to use custom date format\n"

gsettings set org.nemo.preferences show-hidden-files true
echo -e "Nemo is now set to show hidden files - restart file manager for changes to take effect\n"

# Find .json configuration file of Power Manager and set POWER variable to it's path
POWER=$(find /home/$USER/.cinnamon/configs/power@cinnamon.org/ -name '*.json')
# Replace first occurence of line containing '"value"'
awk '/"value":.*/{c++;if(c==1){sub("\"value\":.*","\"value\": \"percentage\"")}}1' $POWER > ~/temp.json && mv ~/temp.json $POWER
echo -e "Power Manager is now set to show battery percentage\n"

gsettings set org.x.editor.preferences.editor scheme oblivion
echo -e "Xed's theme is now set to Oblivion\n"

BASH_ALIASES="/home/$USER/.bash_aliases"
# Check whether '.bash_aliases' exists in user's directory
if [[ -e "$BASH_ALIASES" ]]; then
    # If 'cleanup' alias doesn't exist append it to '.bash_aliases'
    if [[ ! $(grep cleanup $BASH_ALIASES) ]]; then
        echo -e "alias cleanup=\"find . -type f -iname '._*' -printf 'removed file %p\\\n' -delete; find . -type f -iname '.apdisk' -printf 'removed file %p\\\n' -delete; find . -type f -iname '.com.apple.timemachine.donotpresent' -printf 'removed file %p\\\n' -delete; find . -type f -iname '.DS_Store' -printf 'removed file %p\\\n' -delete; find . -type f -iname 'desktop.ini' -printf 'removed file %p\\\n' -delete; find . -type f -iname 'Thumbs.db' -printf 'removed file %p\\\n' -delete; shopt -s nocaseglob; rm -rfv .AppleDouble; rm -rfv .fseventsd; rm -rfv .Spotlight-V100; rm -rfv .TemporaryItems; rm -rfv .Trash*; rm -rfv .Trashes; rm -rfv @eaDir; rm -rfv \*RECYCLE.BIN; rm -rfv FOUND.*; rm -rfv RECYCLED; rm -rfv RECYCLER; rm -rfv System\ Volume\ Information; shopt -u nocaseglob\"" >> $BASH_ALIASES
    fi
    # If 'loopback' alias doesn't exist append it to '.bash_aliases'
    if [[ ! $(grep loopback $BASH_ALIASES) ]]; then
        echo -e "alias loopback=\"sudo modprobe snd-aloop\"" >> $BASH_ALIASES
    fi
    # If 'sshv' alias doesn't exist append it to '.bash_aliases'
    if [[ ! $(grep sshv $BASH_ALIASES) ]]; then
        echo -e "alias sshv=\"ssh -o VisualHostKey=yes\"" >> $BASH_ALIASES
    fi
    # If 'upd' alias doesn't exist append it to '.bash_aliases'
    if [[ ! $(grep upd $BASH_ALIASES) ]]; then
        echo -e "alias upd=\"sudo apt update && sudo apt upgrade -y\"" >> $BASH_ALIASES
    fi
else
    # If '.bash_aliases' doesn't exist - create it and store 'cleanup' alias there
    echo -e "alias cleanup=\"find . -type f -iname '._*' -printf 'removed file %p\\\n' -delete; find . -type f -iname '.apdisk' -printf 'removed file %p\\\n' -delete; find . -type f -iname '.com.apple.timemachine.donotpresent' -printf 'removed file %p\\\n' -delete; find . -type f -iname '.DS_Store' -printf 'removed file %p\\\n' -delete; find . -type f -iname 'desktop.ini' -printf 'removed file %p\\\n' -delete; find . -type f -iname 'Thumbs.db' -printf 'removed file %p\\\n' -delete; shopt -s nocaseglob; rm -rfv .AppleDouble; rm -rfv .fseventsd; rm -rfv .Spotlight-V100; rm -rfv .TemporaryItems; rm -rfv .Trash*; rm -rfv .Trashes; rm -rfv @eaDir; rm -rfv \*RECYCLE.BIN; rm -rfv FOUND.*; rm -rfv RECYCLED; rm -rfv RECYCLER; rm -rfv System\ Volume\ Information; shopt -u nocaseglob\"" > $BASH_ALIASES
    # Append 'loopback' alias to '.bash_aliases'
    echo -e "alias loopback=\"sudo modprobe snd-aloop\"" >> $BASH_ALIASES
    # Append 'sshv' alias to '.bash_aliases'
    echo -e "alias sshv=\"ssh -o VisualHostKey=yes\"" >> $BASH_ALIASES
    # Append 'upd' alias to '.bash_aliases'
    echo -e "alias upd=\"sudo apt update && sudo apt upgrade -y\"" >> $BASH_ALIASES
fi
echo -e "Disk cleanup (namely cleanup), audio loopback (loopback), VisualHostKey SSH (sshv) and system update (upd) aliases have been created\n"

echo "Enabling Firewall... (you will need superuser password)"
read -r -p "Do you want to continue? [Y/n] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo ufw enable
else
    exit 0
fi