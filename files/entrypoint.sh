#!/bin/bash
set -e

USER_NAME="android"
NEW_UID=$(stat -c "%u" .android)
NEW_GID=$(stat -c "%g" .android)

# Change effective UID to the one specified via "-e GOSU_UID=`id -u $USER`"
if [ -n "$GOSU_UID" ]; then
    NEW_UID=$GOSU_UID
fi

# Change effective UID to the one specified via "-e GOSU_GID=`id -g $USER`"
if [ -n "$GOSU_GID" ]; then
    NEW_GID=$GOSU_GID
fi

# Notify user about selected UID/GID
echo "Current UID/GID: $NEW_UID/$NEW_GID"

# Create UNIX group on the fly if it does not exist
if ! grep -q $NEW_GID /etc/group; then
    groupadd --gid $NEW_GID $USER_NAME
fi

useradd --shell /bin/bash --uid $NEW_UID --gid $NEW_GID --non-unique --create-home $USER_NAME
usermod --append --groups wheel $USER_NAME
chown -R $NEW_UID:$NEW_GID /home/$USER_NAME
echo "$USER_NAME:$PASSWORD" | chpasswd

export HOME=/home/$USER_NAME

# Run sshd
/usr/sbin/sshd

# Fix permissions
chown -R 0:$NEW_GID /opt/{android,gradle,gradlew,noVNC}
chmod -R g+w /opt/noVNC/utils
chmod -R g+w /opt/android

# Execute process
exec /usr/local/sbin/gosu $USER_NAME "$@"
