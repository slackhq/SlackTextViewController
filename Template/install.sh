#!/usr/bin/env bash

# Default the folder name
folderName="Slack Templates"

# Determine the install directory.
installDirectory=~/Library/Developer/Xcode/Templates/File\ Templates/"$folderName"

echo "Templates will be installed to $installDirectory"

# Delete the install directory if it already exists to prevent deleted files from lingering.
if [ -d "$installDirectory" ]
then
rm -r "$installDirectory"
fi

# Create the install directory.
mkdir -p "$installDirectory"

# Copy all of the xctemplate folders into the install directory.
cp -r *.xctemplate "$installDirectory"

# Create empty directories that the project templates will copy.
mkdir -p "$installDirectory"/"SlackTextView Controller.xctemplate/Supporting Files/"