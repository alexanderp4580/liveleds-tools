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

    # Install Mender
    JWT_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJmODMxMDI2My1kYjYyLTRjNjQtYjZjNy02NjNlNmM3ZGQzMTIiLCJzdWIiOiJiOTU5YjNlMy1lYzhhLTUyM2MtOWE2OC0wYzg0MmVkMmUzMzUiLCJleHAiOjE2NDcyMDc1OTIsImlhdCI6MTY0NjYwMjc5MiwibWVuZGVyLnRlbmFudCI6IjYyMjUyYTI0ZGMwMDNhMzk4MmRkNzcwNCIsIm1lbmRlci51c2VyIjp0cnVlLCJpc3MiOiJNZW5kZXIgVXNlcnMiLCJzY3AiOiJtZW5kZXIuKiIsIm1lbmRlci5wbGFuIjoiZW50ZXJwcmlzZSIsIm1lbmRlci50cmlhbCI6dHJ1ZSwibWVuZGVyLmFkZG9ucyI6W3sibmFtZSI6ImNvbmZpZ3VyZSIsImVuYWJsZWQiOnRydWV9LHsibmFtZSI6InRyb3VibGVzaG9vdCIsImVuYWJsZWQiOnRydWV9LHsibmFtZSI6Im1vbml0b3IiLCJlbmFibGVkIjp0cnVlfV0sIm5iZiI6MTY0NjYwMjc5Mn0.INhR6kL5MOKpIJfwLe0t4cUsDAElSL6P8czbT_peCAPUe9dCQO2_yo5mTigbM0s6wltfc1I73mZ3hZYMb5OBOnhhjH7SMN4k3U6Y9k5qX4wVPhDM9IOmL-WbtGYhnZHjjKtsVgMW-U-R-NArrPRq2IUYJp_116NXiJW0Ep8MOi0PJLJpBXWCgV89R_qGEjSNNOA-CxmAFczsKn9Jao_1OrKy_rmrs9fITss_JyXpF0mb797hQzm0ZcqOHfQqoQCX5mRWSwRP4PjYHMo5ty_bzgHSzON75n9XwzAnXu85JXsavd2wvAPA0G0QO5A1Kui8LSvVRF_gU3gmfclSnjhr0AydUroOaJIT7FyemUOyzSBh0eECw7je_fmTpO4vIld3ZNy0ipvHhAZQHza0X_DUW1e5PtLImWnQqFfsFL2TdRQBl35gGHTiEnD5KxbI9iKmFKipSVGMIqwLBYvXKLWKqlwaCy-Ec0wGQ9uQOUWeGx8T3dmAe7x3jf-9iqhq_wpA"
    TENANT_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJtZW5kZXIudGVuYW50IjoiNjIyNTJhMjRkYzAwM2EzOTgyZGQ3NzA0IiwiaXNzIjoiTWVuZGVyIiwic3ViIjoiNjIyNTJhMjRkYzAwM2EzOTgyZGQ3NzA0In0.pFnVYBZQOECauxNlYC6B1oN2WdAmzt_iHJpcv6xnSuvvr_MG04dsiQNlvhVGbjSzkfImDasXHK2rYdzRHLWf0YgoPiLgSWrsL25CoefWACh6UynUaMeeV0bvbXJuDvOtd9UgdUabwyyAtSH2jEHa98vqngF47e5BZ0nXO3d58DVnExiqEty5o0H7Zrl4_OW09BUcbaNJTVEqExOewJpT-MMECzva9u5xUvy-cHpf56f3tnZLi08zkAz3E8tyxASjYOJ-b6wFQlkfw6xz6-1CDb_1xvDINn9m4Ro9aTajxPjeFjciTDSqErkW5q8LnYU4ATftuhd5O_pAZ_Z3WL5q1y96E6U87eYBW_oNLbJGnvcLujqDZItwAKodcjEZweLjlTA3pdRT3OgqrJRxAbzH9uXFfWyVYxTV4RZi3wNCl-6w0sSPyR04dhY5W-8Yixp14M8_dDsDa7EDWQ3UubTQjf5prMuEAGhImIF3ngReJrRxvV_cnSp1XOGzeqSjUXKH"
    wget -O- https://get.mender.io | sudo bash -s -- --demo --commercial --jwt-token $JWT_TOKEN -- --quiet --device-type "raspberrypi3" --tenant-token $TENANT_TOKEN --demo --hosted-mender

    reboot
fi

# Check for pulseaudio
pulseaudio --k

echo "Starting pulseaudio."
pulseaudio &
sleep 5

pacmd load-module module-remap-source source_name=virt_ll_source_mono master=alsa_output.platform-bcm2835_audio.analog-stereo.monitor channel_map=mono channels=1
pacmd load-module module-loopback source=alsa_output.platform-bcm2835_audio.analog-stereo.monitor sink=alsa_output.platform-bcm2835_audio.digital-stereo latency_msec=20
pactl set-default-sink alsa_output.platform-bcm2835_audio.analog-stereo

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