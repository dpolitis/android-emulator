# Android-emulator

Android-emulator is a Docker image with Android SDK and emulator inside. Big advantage is that you can use this container to access the emulator through your browser.

### Use:
Download jdk-8u241-linux-x64.rpm from Oracle and put it on "files" folder, after git clone command.
```sh
$ git clone https://github.com/dpolitis/android-emulator.git android-emulator
$ cd android-emulator
$ docker build -t android-emu:tv .
$ docker-compose up -d
```

By default it will create and run API 29 (x86) for you, but some other versions also supported. You can use docker-compose.yml to set the following environment variables, before invoking docker-compose:
ANDROID_API
ANDROID_DEVICE

### How to connect to emulator

Emulator container exposed 4 port's by default:
tcp/22 - SSH connection to container (login: root, password: android, change this if you are security concerned)

* tcp/32809 - Emulator ADB
* tcp/32810 - Emulator Control port
* tcp/32811 - Container console, via ssh 
* tcp/32812 - noVNC connection (supports pointing device and keyboard, crashes when used on sidebar, for unknown reason..)

#### Access emulator via adb from your pc
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
root@generic_x86:/ #
```

#### Access emulator control port from your pc
```sh
$ telnet 0.0.0.0 32810
```
You need first to Use ssh access to obtain the passphrase for the control port of the emulator.

#### Access docker container via ssh from your pc
```sh
$ ssh -p32811 android@localhost
```

#### Access emulator device via browser from your pc
Point your browser to http://localhost:32808/vnc.html to access the emulator.
