#!/bin/sh

# install eli
wget https://raw.githubusercontent.com/cryon-io/eli/master/install.sh -O /tmp/install.sh && sh /tmp/install.sh

# install ami
LATEST=$(curl -sL https://api.github.com/repos/cryon-io/ami/releases/latest | grep tag_name | sed 's/  "tag_name": "//g' | sed 's/",//g')

TMP_NAME="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

wget "https://github.com/cryon-io/ami/releases/download/$LATEST/ami.lua" -O "$TMP_NAME" &&
    mv "$TMP_NAME" /usr/sbin/ami &&
    chmod +x /usr/sbin/ami &&
    echo "ami $LATEST successfuly installed."
