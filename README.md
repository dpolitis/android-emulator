# Android-emulator

Android-emulator is a Docker image with Android SDK, gradle and emulator inside. Big advantage is that you can use this container to access the emulator through your browser.

## Use:
- Clone repository.
- Download jdk-8u251-linux-x64.rpm from Oracle and put it on "files" folder.
- Review Dockerfile and change any variable to your liking (for ex. ANDROID_API)
- If you are using "google_apis_playstore" API, you need to create a pair of keys for adb to use. You can do that by:
```sh
$ adb keygen ~/.android/adbkey
```
- Build the container and bring it up.
```sh
$ cd android-emulator
$ docker build -t android-emu:25 .
$ docker-compose up -d
```

By default it will create and run API 25 (x86) for you (with API: google_apis), but other versions are also supported via changing the appropriate variable in the Dockerfile before building (ANDROID_PLATFORM). You can use docker-compose.yml to set the following environment variables, before invoking docker-compose:
ANDROID_DEVICE

## How to connect to emulator
By default docker-compose exposes the folloing ports:
* tcp/32809 - Emulator ADB
* tcp/32810 - Emulator Control port
* tcp/32811 - SSH connection to container (login: root, password: android, change this if you are security concerned) 
* tcp/32812 - noVNC connection (supports pointing device and keyboard, crashes when used on sidebar, for unknown reason..)

### Access emulator via adb from your pc
```sh
$ adb kill-server
$ adb connect 0.0.0.0:32809
* daemon not running. starting it now on port 5037 *
* daemon started successfully *
connected to 0.0.0.0:32809

$ adb devices
List of devices attached
0.0.0.0:32809   device

$ adb shell
generic_x86:/ $
```

### Access emulator control port from your pc
```sh
$ telnet 0.0.0.0 32810
```
You need first to Use ssh access to obtain the passphrase for the control port of the emulator.

### Access docker container via ssh from your pc
```sh
$ ssh -p32811 android@localhost
```

### Access emulator device via browser from your pc
Point your browser to http://localhost:32808/vnc.html to access the emulator.


## Tips

### Enable Skia rendering for Android UI (may not work, YMMV)
When using images for API level 27 or higher, the emulator can render the Android UI with Skia. Skia helps the emulator render graphics more smoothly and efficiently.

To enable Skia rendering, use the following commands in adb shell (after connecting to the emulator via adb):
```sh
generic_x86:/ $ su
generic_x86:/ # setprop debug.hwui.renderer skiagl
generic_x86:/ # stop
generic_x86:/ # start
```

### Disable/enable software navigation keys in Android (when sidebar crashes)
use the following commands in adb shell (after connecting to the emulator via adb):
```sh
generic_x86:/ $ su

//To turn ON soft keys
generic_x86:/ # setprop qemu.hw.mainkeys 0

//To turn OFF soft keys
generic_x86:/ # setprop qemu.hw.mainkeys 1

generic_x86:/ # stop
generic_x86:/ # start
```

### FAQ
- The container is supposed to be run using docker service. You can run it using podman, but you need to use "podman run .." syntax equivalent to the docker-compose parameters (or use kubernetes..). You must also set "--privileged" for the /dev/kvm device to be available into the container with the right permissions.
- The container uses "-gpu host" when invoking the avdmanager, so the /dev/kvm device should be available. This means it runs only in linux systems with the kvm module loaded and with virtualization enabled in BIOS settings. If you use windows docker, install HAXM and search google for the equivalent settings to enable hardware  acceleration into the container (or use "-gpu off" in the Dockerfile and build the container again, without acceleration).
