#!/usr/bin/env bash

################################################################################
# Script name:  optimiseForSSD.sh
# Description:  This script automates applying SSD preserving OS settings in
#               Linux Mint. It changes automatic TRIM job to daily, creates
#               alias for manual TRIM job, reduces swap usage, reduces browser
#               disk write activity and disables file "access time stamps".
# Usage:        ./optimiseForSSD.sh
# Author:       Tomasz Targiel
# Version:      1.0
# Date:         28.09.2022
################################################################################

# Additionaly you should apply following:
# Update SSD firmware
# Choose Ext4 filesystem during installation
# In BIOS change SATA Configuration to AHCI Mode
# In BIOS change External SATA 6GB/s Configuration to AHCI Mode
# Keep 20% of every partition free
# Do not defrag
# Do not hibernate

# If '/etc/systemd/system/fstrim.timer.d/override.conf' exists
if [[ -e "/etc/systemd/system/fstrim.timer.d/override.conf" ]]; then
    echo -e "********************************\n/etc/systemd/system/fstrim.timer.d/override.conf found, displaying TRIM's configuration:"
    systemctl cat fstrim.timer

    echo -e "\n********************************\nLast time TRIM was used:"
    journalctl | grep fstrim.service
else
    echo "Creating TRIM's configuration override..."
    sudo mkdir /etc/systemd/system/fstrim.timer.d
    [ $? -eq 0 ] && echo "Successfully created fstrim.timer.d directory!" || echo "Failed to create fstrim.timer.d directory!"

    # Append TRIM's configuration override to '/etc/systemd/system/fstrim.timer.d/override.conf' with superuser privileges (could be done only when using 'sh -c')
    sudo sh -c 'echo "[Timer]\nOnCalendar=\nOnCalendar=daily" > /etc/systemd/system/fstrim.timer.d/override.conf'
    [ $? -eq 0 ] && echo "Successfully set an automatic TRIM job to daily! To apply restart computer" || echo "Failed to set automatic TRIM job to daily!"
fi

EXECTRIM="/home/$USER/.execTRIM.sh"
# If '.execTRIM.sh' doesn't exist
if [[ ! -f "$EXECTRIM" ]]; then
    echo -e "\nCreating script for manual TRIM job..."
    # In user's directory create '.execTRIM.sh' script by redirecting echo output
    echo -e '#!/usr/bin/env bash\n\nread -r -p "Did you make sure to close all other applications? [Y/n] " response\nif [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then\n    sudo fstrim -av\nelse\n    exit 0\nfi' > $EXECTRIM
    [ $? -eq 0 ] && echo "Success!" || echo "Fail!"
    # If you encounter problems with executing 'fstrim -av' - use 'sudo fstrim -v /' instead

    # Add executable properties to '.execTRIM.sh'
    chmod +x $EXECTRIM
    [ $? -eq 0 ] && echo "Successfully marked TRIM's manual job script as executable!" || echo "Failed to mark TRIM's manual job script as executable!"
fi

echo -e "\nCreating TRIM alias (namely trim) for manual execution..."
BASH_ALIASES="/home/$USER/.bash_aliases"
# Check whether '.bash_aliases' exists in user's directory
if [[ -e "$BASH_ALIASES" ]]; then
    # If 'trim' alias doesn't exist append it to '.bash_aliases'
    if [[ ! $(grep trim $BASH_ALIASES) ]]; then
        echo -e "alias trim=\"$EXECTRIM\"" >> $BASH_ALIASES
        [ $? -eq 0 ] && echo "Success!" || echo "Fail!"
    else
        echo "TRIM alias already exists!"
    fi
else
    # If '.bash_aliases' doesn't exist - create it and store 'trim' alias there
    echo -e "alias trim=\"$EXECTRIM\"" > $BASH_ALIASES
    [ $? -eq 0 ] && echo "Success!" || echo "Fail!"
fi

# If swappiness level equals to 60% and '/etc/sysctl.conf' doesn't contain 'vm.swappiness=25'
if [[ $(cat /proc/sys/vm/swappiness) -eq 60 && ! $(grep vm.swappiness=25 /etc/sysctl.conf) ]]; then
    echo -e "\nReducing swappiness level to 25%..."
    # Using superuser privileges append 'vm.swappiness=25' to '/etc/sysctl.conf'
    sudo sh -c 'echo "# Reduce swappiness level\nvm.swappiness=25" >> /etc/sysctl.conf'
    [ $? -eq 0 ] && echo "Success! To apply swappiness level changes you have to restart your computer!" || echo "Fail!"
else
    echo -e "\n********************************\nCurrent swappiness level is set to:" $(cat /proc/sys/vm/swappiness) "%"
fi

echo -e "\nDisabling \"access time stamps\" from files..."
# If '/etc/fstab' doesn't contain 'noatime,errors=remount-ro' nor 'errors=remount-ro'
if [[ $(grep noatime,errors=remount-ro /etc/fstab) || ! $(grep errors=remount-ro /etc/fstab) ]]; then
    echo "Either \"access time stamps\" are already disabled or this drive doesn't use them!"
else
    # Replace ' errors=remount-ro' with ' noatime,errors=remount-ro' in '/etc/fstab'
    sudo sed -i 's/ errors=remount-ro/ noatime,errors=remount-ro/' /etc/fstab
    [ $? -eq 0 ] && echo "Success! To apply \"access time stamp\" changes you have to restart your computer!" || echo "Fail!"
fi

# For this part to work - Firefox/LibreWolf had to be opened at least once before
echo -e "\nChanging Firefox/LibreWolf disk-writing preferences... (if Firefox/LibreWolf is opened - it will be force shut)"
read -r -p "Do you want to continue? [Y/n] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # Kill browser processes
    pkill firefox
    pkill librewolf

    # For every 'prefs.js' found in '.mozilla' or '.librewolf' directories
    for i in $(find /home/$USER/.mozilla/firefox /home/$USER/.librewolf -name 'prefs.js'); do
        # If there already is 'browser.cache.memory.enable' property in current 'prefs.js'
        if [[ $(grep browser.cache.memory.enable $i) ]]; then
            # Replace it's value with 'true'
            sed -i 's/"browser.cache.memory.enable",.*/"browser.cache.memory.enable", true);/' $i
        else
            # Append preferences to 'prefs.js'
            echo "user_pref(\"browser.cache.memory.enable\", true);" >> $i
        fi
        [ $? -eq 0 ] && echo "Successfully enabled network caching to RAM! [$i]" || echo "Failed to enable network caching to RAM! [$i]"

        # If there already is 'browser.cache.memory.capacity' property in current 'prefs.js'
        if [[ $(grep browser.cache.memory.capacity $i) ]]; then
            # Replace it's value with '1048576'
            sed -i 's/"browser.cache.memory.capacity",.*/"browser.cache.memory.capacity", 1048576);/' $i
        else
            # Append preferences to 'prefs.js'
            echo "user_pref(\"browser.cache.memory.capacity\", 1048576);" >> $i
        fi
        [ $? -eq 0 ] && echo "Successfully changed RAM cache capacity to 1 GB! [$i]" || echo "Failed to change RAM cache capacity to 1 GB! [$i]"

        # If there already is 'browser.sessionstore.interval' property in current 'prefs.js'
        if [[ $(grep browser.sessionstore.interval $i) ]]; then
            # Replace it's value with '15000000'
            sed -i 's/"browser.sessionstore.interval",.*/"browser.sessionstore.interval", 15000000);/' $i
        else
            # Append preferences to 'prefs.js'
            echo "user_pref(\"browser.sessionstore.interval\", 15000000);" >> $i
        fi
        [ $? -eq 0 ] && echo "Successfully disabled sessionstore! [$i]" || echo "Failed to disable sessionstore! [$i]"
    done
else
    exit 0
fi