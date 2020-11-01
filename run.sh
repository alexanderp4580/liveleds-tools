#! /bin/bash

# Download latest binary and generate md5 file.
function downloadLatestBinary() {
    VERSION_OUTPUT=$(curl https://liveleds-server.herokuapp.com)
    VERSION=$(jq -r '.version' <<<"$VERSION_OUTPUT")
    MD5=$(jq -r '.md5' <<<"$VERSION_OUTPUT")
    echo "Found latest version $VERSION with MD5 hash $MD5"
    echo "Downloading latest binary"
    curl -o liveleds -L https://liveleds-server.herokuapp.com/latest-binary
    chmod +x liveleds
    echo "Saving MD5 to file"
    echo $MD5 >>md5.txt
}

# Start
echo "Starting script."

# Disable wlan0 Power Management
/sbin/iw wlan0 set power_save off

# Discard locale information.
export LC_ALL=C; unset LANGUAGE

# Check for pulseaudio
pulseaudio --check

if [ $? -ne 0 ]; then
    echo "Starting pulseaudio"
    pulseaudio &
    sleep 5
else
    echo "Pulseaudio running"
fi

# Set exit on error after the check.
set -e

# Get binary
if [ -f "liveleds" ] && [ -f "md5.txt" ]; then
    echo "liveleds and MD5 exist"
else
    echo "liveleds doesn't exist. Trying to download."
    downloadLatestBinary
fi

# Validate binary
MD5_EXPECTED=$(cat md5.txt)
MD5_RESULT=$(md5sum -b liveleds | awk '{print $1}')

echo "Expected ${MD5_EXPECTED}"
echo "Result   ${MD5_RESULT}"

# Compare MD5 sums
if [[ "$MD5_EXPECTED" != "$MD5_RESULT" ]]; then
    echo "Failed to match MD5 hashes"
    rm md5.txt
    exit 1
fi

# Create database dirs
mkdir -p db/config

# Get source name
SOURCE_NAME=$(pacmd list-sources | grep -e 'name:' -e 'index:' | grep input.usb | awk -F[\<\>] '{print $2}')
if [[ -z "$SOURCE_NAME" ]]; then
    echo "Failed to find source device."
    exit 1
fi
echo "Source name: $SOURCE_NAME"

echo "Running"
./liveleds --verbosity 0 --source device --source-name $SOURCE_NAME --sample-rate 48000 --app-config config/db/app.json --config config/db/config
