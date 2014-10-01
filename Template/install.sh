#!/usr/bin/env bash

# Default the folder name
folderName="Slack Templates"

# Determine the source directory.
sourceDirectory=`dirname "$BASH_SOURCE"`

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
cp -r "$sourceDirectory"/*.xctemplate "$installDirectory"
