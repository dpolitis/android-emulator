# Android development environment using Centos.

FROM centos:7

# Specially for SSH access and port redirection
ENV PASSWORD android

# Installation variables
ARG ANDROID_SDK_VERSION="6200805"
# ARCH can be "x86", "x86_64", "armeabi-v7a", "arm64-v8a", "mips"
ENV ANDROID_ARCH="x86"
# ANDROID_API can be "default","google_apis", "google_apis_playstore", "android-tv", "android-wear", "android-wear-cn"
ENV ANDROID_API="google_apis_playstore"
# ANDROID_PLATFORM can be "android-10"-"android-29"
ENV ANDROID_PLATFORM="android-29"
ENV ANDROID_DEVICE="7in WSVGA (Tablet)"

ENV BUILD_TOOLS="29.0.3"
ENV GRADLE_TOOLS="6.3"

# Add android tools and platform tools to PATH
ENV ANDROID_HOME="/opt/android"
ENV GRADLE_HOME="/opt/gradle/gradle-${GRADLE_TOOLS}"
ENV PATH="${PATH}:${GRADLE_HOME}/bin:/opt/gradlew:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/build-tools/${BUILD_TOOLS}"
ENV LD_LIBRARY_PATH="${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/qt/lib"

# Export JAVA_HOME variable
ENV JAVA_HOME="/usr/java/jdk1.8.0_241-amd64"

# Export noVNC variables
ENV DISPLAY=:1 \
    SCREEN=0 \
    SCREEN_WIDTH=1440 \
    SCREEN_HEIGHT=810 \
    SCREEN_DEPTH=24+32 \
    LOCAL_PORT=5900 \
    TARGET_PORT=6080 \
    TIMEOUT=1 \
    VIDEO_PATH=/tmp/video

# Expose ADB, ADB control and VNC ports
EXPOSE 22
EXPOSE 5554
EXPOSE 5555
EXPOSE 6080

COPY files/jdk-8u241-linux-x64.rpm /tmp/jdk-8u241-linux-x64.rpm

# Update packages
RUN yum makecache; \
    yum -y update; \
    yum -y install net-tools \
        openssh-server \
	socat \
	unzip \
	wget \
	git \
	epel-release \
	alsa-lib \
	pulseaudio-libs \
	mesa-dri-drivers \
	libXcomposite \
	libXcursor; \
    yum localinstall -y /tmp/jdk-8u241-linux-x64.rpm

# Install x11vnc
RUN sed -i "s/baseurl/#baseurl/g" /etc/yum.repos.d/epel.repo; \
    sed -i "s/baseurl/#baseurl/g" /etc/yum.repos.d/epel-testing.repo; \
    sed -i "s/#metalink/metalink/g" /etc/yum.repos.d/epel.repo; \
    sed -i "s/#metalink/metalink/g" /etc/yum.repos.d/epel-testing.repo; \
    yum makecache; \
    yum install -y x11vnc; \
    yum clean all

# Fix ssh login
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N ""; \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N ""; \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -q -N ""; \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -q -N ""

RUN mkdir /var/run/sshd; \
    echo "root:$PASSWORD" | chpasswd; \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    echo "export VISIBLE=now" >> /etc/profile

ENV NOTVISIBLE "in users profile"

# Install android sdk
RUN wget -nv https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -P /tmp; \
    unzip -d /opt /tmp/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip; \
    mkdir -p /opt/android/cmdline-tools; \
    mv /opt/tools /opt/android/cmdline-tools/latest; \
    chown -R root:root /opt/android

# Install latest android tools and system images
RUN yes | sdkmanager --licenses; \
    sdkmanager --install \
    "cmdline-tools;latest" \
    "platform-tools" \
    "emulator" \
    "platforms;${ANDROID_PLATFORM}" \
    "build-tools;${BUILD_TOOLS}" \
    "system-images;${ANDROID_PLATFORM};${ANDROID_API};${ANDROID_ARCH}"

# Install Grandle
RUN wget -nv https://services.gradle.org/distributions/gradle-${GRADLE_TOOLS}-bin.zip -P /tmp; \
    unzip -d /opt/gradle /tmp/gradle-${GRADLE_TOOLS}-bin.zip; \
    mkdir /opt/gradlew; \
    /opt/gradle/gradle-${GRADLE_TOOLS}/bin/gradle wrapper --gradle-version ${GRADLE_TOOLS} --distribution-type all -p /opt/gradlew; \
    /opt/gradle/gradle-${GRADLE_TOOLS}/bin/gradle wrapper -p /opt/gradlew

# Run noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC; \
    cd /opt/noVNC; \
    git checkout $(git describe --tags)

# Cleanup
RUN rm -rf /tmp/*

# Add entrypoint
ADD files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
