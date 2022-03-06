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

# Disable wlan0 Power Management
/sbin/iw wlan0 set power_save off

# Discard locale information.
export LC_ALL=C; unset LANGUAGE

# Install librespot
if ! command -v librespot &> /dev/null
then
    echo "librespot could not be found. Installing."
    curl -k -o /tmp/raspotify.deb -L https://github.com/dtcooper/raspotify/releases/download/0.31.7/raspotify_0.31.7.librespot.v0.3.1-54-gf4be9bb_armhf.deb
    sudo apt -y install /tmp/raspotify.deb
    rm /tmp/raspotify.deb
    systemctl stop raspotify
    systemctl disable raspotify
    systemctl mask raspotify
    cp librespot.service /etc/systemd/system/librespot.service
    systemctl daemon-reload
    systemctl enable librespot
    systemctl start librespot
fi

# Enable soundcard
SOUNDCARD=$(sed -n '/^[[:blank:]]*CONFIG_SOUNDCARD=/{s/^[^=]*=//;p;q}' /boot/dietpi.txt)
if [ "$SOUNDCARD" != "rpi-bcm2835-3.5mm" ]; then
    echo "Enabling soundcard."
    apt-get update --allow-releaseinfo-change
    apt -y install pulseaudio
    /boot/dietpi/func/dietpi-set_hardware soundcard "rpi-bcm2835-3.5mm"
    echo "hdmi_ignore_edid_audio=1" >> /boot/config.txt
    reboot
fi

# Check for pulseaudio
pulseaudio --k

echo "Starting pulseaudio."
pulseaudio &
sleep 5

pacmd load-module module-remap-source source_name=virt_ll_source_mono master=alsa_output.platform-bcm2835_audio.analog-stereo.monitor channel_map=mono channels=1
pacmd load-module module-loopback source=alsa_output.platform-bcm2835_audio.analog-stereo.monitor sink=alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo latency_msec=20
pactl set-default-sink alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo

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

# Get source name
SOURCE_NAME=$(pacmd list-sources | grep device.description | grep Mono | awk -F'"' '$0=$2')
if [[ -z "$SOURCE_NAME" ]]; then
    echo "Failed to find source device."
    exit 1
fi
echo "Source name: $SOURCE_NAME."

echo "Running."
./liveleds --verbose --source device --source-name "$SOURCE_NAME" --sample-rate 44100 --database "db"