#!/usr/bin/env bash

################################################################################
# Script name:  personalisedVSCode.sh
# Description:  This script automates installation of Visual Studio Code
#               extensions in Linux Mint, personalises settings and keybindings.
# Usage:        ./personalisedVSCode.sh
# Author:       Tomasz Targiel
# Version:      1.0
# Date:         28.09.2022
################################################################################

# Declare EXTENSIONS array populated with full extension names (publisher.extension)
EXTENSIONS=("dsznajder.es7-react-js-snippets" "esbenp.prettier-vscode" "ms-python.python" "ms-vscode-remote.remote-ssh" "ms-vscode.cpptools" "ms-vscode.hexeditor" "ritwickdey.LiveServer" "Tyriar.sort-lines")

# Install extensions
for i in "${EXTENSIONS[@]}"
do
    code --install-extension "$i"
done

CODE_SETTINGS="/home/$USER/.config/Code/User/settings.json"
# If 'settings.json' doesn't exist in Code User's directory or it doesn't contain any settings
if [[ ! -f "$CODE_SETTINGS" || ! $(grep '".*":' $CODE_SETTINGS) ]]; then
    # Write desired content to 'settings.json'
    echo -e '{\n    "editor.bracketPairColorization.enabled": true,\n    "editor.guides.bracketPairs": "active",\n    "editor.multiCursorModifier": "ctrlCmd",\n    "prettier.tabWidth": 4,\n    "telemetry.telemetryLevel": "off"\n}' > $CODE_SETTINGS
else
    # Inject desired settings right before ending curly braces
    sed -i -z 's/\n}/,\n    "editor.bracketPairColorization.enabled": true,\n    "editor.guides.bracketPairs": "active",\n    "editor.multiCursorModifier": "ctrlCmd",\n    "prettier.tabWidth": 4,\n    "telemetry.telemetryLevel": "off",\n}/' $CODE_SETTINGS
    # Print settings content placed between curly braces, without empty lines, without repetitions, without last comma - and overwrite 'settings.json'
    echo -e "{\n$(awk -F '[{}]' '{print $1}' $CODE_SETTINGS | grep -v '^$' | sort -u | head -c-2)\n}" > $CODE_SETTINGS
fi

CODE_KEYBINDINGS="/home/$USER/.config/Code/User/keybindings.json"
# Check whether 'keybindings.json' exists in Code User's directory and if it contains any binds there
if [[ -e "$CODE_KEYBINDINGS" && $(grep '"key":' $CODE_KEYBINDINGS) ]]; then
    # If '"-sortLines.sortLines"' doesn't exist
    if [[ ! $(grep '"-sortLines.sortLines"' $CODE_KEYBINDINGS) ]]; then
        sed -i -z 's/\n]/,\n    {\n        "key": "f9",\n        "command": "-sortLines.sortLines",\n        "when": "editorTextFocus"\n    }\n]/' $CODE_KEYBINDINGS
    fi
    # If '"sortLines.sortLinesNatural"' doesn't exist
    if [[ ! $(grep '"sortLines.sortLinesNatural"' $CODE_KEYBINDINGS) ]]; then
        sed -i -z 's/\n]/,\n    {\n        "key": "f9",\n        "command": "sortLines.sortLinesNatural",\n        "when": "editorTextFocus"\n    }\n]/' $CODE_KEYBINDINGS
    fi
else
    # If 'keybindings.json' doesn't exist or it doesn't contain any binds - write desired content to it
    echo -e '// Place your key bindings in this file to override the defaults\n[\n    {\n        "key": "f9",\n        "command": "-sortLines.sortLines",\n        "when": "editorTextFocus"\n    },\n    {\n        "key": "f9",\n        "command": "sortLines.sortLinesNatural",\n        "when": "editorTextFocus"\n    }\n]' > $CODE_KEYBINDINGS
fi