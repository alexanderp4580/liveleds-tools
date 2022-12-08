#! /bin/bash
set -x

# Download latest binary and generate md5 file.
function downloadLatestBinary() {
    VERSION_OUTPUT=$(curl https://liveleds.io/version/latest)
    VERSION=$(jq -r '.version' <<<"$VERSION_OUTPUT")
    MD5=$(jq -r '.md5' <<<"$VERSION_OUTPUT")
    echo "Found latest version $VERSION with MD5 hash $MD5"
    echo "Downloading latest binary"
    curl -o liveleds -L https://liveleds.io/version/latest/binary
    chmod +x liveleds
    echo "Saving MD5 to file"
    echo $MD5 >>md5.txt
}

# Start
echo "Starting script."

# Check for missing libs for upgrade
dpkg -s libfftw3-3 2>/dev/null >/dev/null || apt-get update --allow-releaseinfo-change || sudo apt-get -y install fftw3
dpkg -s libfftw3-dev 2>/dev/null >/dev/null || apt-get update --allow-releaseinfo-change || sudo apt-get -y install libfftw3-dev
dpkg -s libblas3 2>/dev/null >/dev/null || apt-get update --allow-releaseinfo-change || sudo apt-get -y install libblas3
dpkg -s libblas-dev 2>/dev/null >/dev/null || apt-get update --allow-releaseinfo-change || sudo apt-get -y install libblas-dev

# Disable wlan0 Power Management
/sbin/iw wlan0 set power_save off

# Discard locale information.
export LC_ALL=C; unset LANGUAGE
sleep 5

# Check for pulseaudio
pulseaudio --k

echo "Starting pulseaudio."
pulseaudio &
sleep 5

# Set exit on error after the check.
set -e

# Get binary
if [ -f "liveleds" ] && [ -f "md5.txt" ]; then
    echo "liveleds and MD5 exist."
else
    echo "liveleds doesn't exist. Trying to download."
    downloadLatestBinary || true
fi

# Validate binary
MD5_EXPECTED=$(cat md5.txt)
MD5_RESULT=$(md5sum -b liveleds | awk '{print $1}')

echo "Expected ${MD5_EXPECTED}"
echo "Result   ${MD5_RESULT}"

# Compare MD5 sums
if [[ "$MD5_EXPECTED" != "$MD5_RESULT" ]]; then
    echo "Failed to match MD5 hashes. Removing md5 file."
    rm md5.txt
fi

# Restart avahi just in case.
systemctl restart avahi-daemon.service

# Get source name
SOURCE_NAME=$(pacmd list-sources | grep device.description | egrep "Mono|\"CM106" | awk -F'"' '$0=$2')
if [[ -z "$SOURCE_NAME" ]]; then
    echo "Failed to find source device."
fi
echo "Source name: $SOURCE_NAME."

echo "Running."
nice -n -20 ./liveleds --verbose --source device --source-name "$SOURCE_NAME" --sample-rate 48000 --database "db"