#!/bin/bash

if [[ $ANDROID_PLATFORM == "" ]]; then
    ANDROID_PLATFORM="android-25"
    echo "Using default emulator $ANDROID_PLATFORM"
fi

if [[ $ANDROID_API == "" ]]; then
    ANDROID_API="default"
    echo "Using default api $ANDROID_API"
fi

if [[ $ANDROID_ARCH == "" ]]; then
    ANDROID_ARCH="x86"
    echo "Using default arch $ANDROID_ARCH"
fi

if [[ $ANDROID_DEVICE == "" ]]; then
    ANDROID_DEVICE="pixel_2"
    echo "Using default device ${ANDROID_DEVICE}"
fi

echo ANDROID_PLATFORM  = "Requested ANDROID_API: ${ANDROID_PLATFORM} (${ANDROID_ARCH}) emulator."
adb start-server

# Point DISPLAY to virtual X Server
export DISPLAY=:0

# Start Xvfb at DISPLAY :0
Xvfb :0 -screen 0 1440x810x24 > /tmp/xvfb.log 2>&1 &

# Start a VNC server and point it to the same display
x11vnc -display :0 -quiet -nopw -rfbport 5901 -bg -o /tmp/vnc.log

# Proxy websocket traffic to raw tcp traffic
/opt/noVNC/utils/launch.sh --vnc localhost:5901 > /tmp/novnc.log 2>&1 &

# Detect ip and forward ADB ports to outside interface
ip=$(ifconfig  | grep 'inet' | grep -v '127.0.0.1' | awk '{ print $2 }')
socat tcp-listen:5554,bind=$ip,fork tcp:127.0.0.1:5554 &
socat tcp-listen:5555,bind=$ip,fork tcp:127.0.0.1:5555 &

# Start emulator for a pre-defined avd
echo "no" | avdmanager create avd -f -n ${ANDROID_PLATFORM}-emu -k "system-images;${ANDROID_PLATFORM};${ANDROID_API};${ANDROID_ARCH}" -d ${ANDROID_DEVICE}
emulator -avd ${ANDROID_PLATFORM}-emu -gpu host -no-audio -no-boot-anim -nojni -netfast -qemu -enable-kvm > /tmp/emulator.log 2>&1
