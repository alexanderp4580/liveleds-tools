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

    # Check for missing libs for upgrade
    dpkg -s libfftw3-3 2>/dev/null >/dev/null || (apt-get update --allow-releaseinfo-change && sudo apt-get -y install libfftw3)
    dpkg -s libfftw3-dev 2>/dev/null >/dev/null || (apt-get update --allow-releaseinfo-change && sudo apt-get -y install libfftw3-dev)
    dpkg -s libblas3 2>/dev/null >/dev/null || (apt-get update --allow-releaseinfo-change && sudo apt-get -y install libblas3)
    dpkg -s libblas-dev 2>/dev/null >/dev/null || (apt-get update --allow-releaseinfo-change && sudo apt-get -y install libblas-dev)
    dpkg -s avahi-utils 2>/dev/null >/dev/null || (apt-get update --allow-releaseinfo-change && sudo apt-get -y install avahi-utils)

    chmod +x liveleds
    echo "Saving MD5 to file"
    echo $MD5 >>md5.txt
}

# Start
echo "Starting script."

# Disable wlan0 Power Management
/sbin/iw wlan0 set power_save off

# Discard locale information.
export LC_ALL=C
unset LANGUAGE
sleep 3

# Check for pulseaudio
pulseaudio --k

echo "Starting pulseaudio."
pulseaudio &
sleep 3

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

# Stop AP service if LAN detected
if $(ethtool eth0 | grep -q "Link detected: yes"); then
    echo "Stopping AP"
    systemctl stop create_ap.service
fi

# Get source name
SOURCE_NAME=$(pacmd list-sources | grep device.description | egrep "Mono|CM106|USB PnP Audio Device Analog Stereo" | awk -F'\"' '$0=$2' | tr -d '\n')
if [[ -z "$SOURCE_NAME" ]]; then
    echo "Failed to find source device. Retrying #1"
    sleep 3

    # Check for pulseaudio
    pulseaudio --k

    echo "Starting pulseaudio."
    pulseaudio &
    sleep 3
    SOURCE_NAME=$(pacmd list-sources | grep device.description | egrep "Mono|CM106|USB PnP Audio Device Analog Stereo" | awk -F'\"' '$0=$2' | tr -d '\n')
    if [[ -z "$SOURCE_NAME" ]]; then
        echo "Failed to find source device. Retrying #2"
        sleep 6

        # Check for pulseaudio
        pulseaudio --k

        echo "Starting pulseaudio. #2"
        pulseaudio &
        sleep 6
        SOURCE_NAME=$(pacmd list-sources | grep device.description | egrep "Mono|CM106|USB PnP Audio Device Analog Stereo" | awk -F'\"' '$0=$2' | tr -d '\n')
        if [[ -z "$SOURCE_NAME" ]]; then
            echo "Failed to find source device. Retrying #3"
            sleep 10

            # Check for pulseaudio
            pulseaudio --k

            echo "Starting pulseaudio. #3"
            pulseaudio &
            sleep 10
            SOURCE_NAME=$(pacmd list-sources | grep device.description | egrep "Mono|CM106|USB PnP Audio Device Analog Stereo" | awk -F'\"' '$0=$2' | tr -d '\n')
        fi
    fi
fi
echo "Source name: $SOURCE_NAME."

echo "Running."
nice -n -20 ./liveleds --verbose --source device --source-name "$SOURCE_NAME" --sample-rate 48000 --database "db"
