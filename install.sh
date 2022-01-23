#!/bin/sh

TMP_NAME="/tmp/$(head -n 1 -c 32 /dev/urandom | tr -dc 'a-zA-Z0-9'| fold -w 32)"

if which curl >/dev/null; then
    set -- curl -L --progress-bar -o "$TMP_NAME"
    LATEST=$(curl -sL https://api.github.com/repos/alis-is/ami/releases/latest | grep tag_name | sed 's/  "tag_name": "//g' | sed 's/",//g')
else
    set -- wget -q --show-progress -O "$TMP_NAME"
    LATEST=$(wget -qO- https://api.github.com/repos/alis-is/ami/releases/latest | grep tag_name | sed 's/  "tag_name": "//g' | sed 's/",//g')
fi

# install eli
echo "Downloading eli setup script..."
if ! "$@" https://raw.githubusercontent.com/alis-is/eli/master/install.sh; then
    echo "Failed to download eli, please retry ... "
    exit 1
fi
if ! sh "$TMP_NAME"; then
    echo "Failed to download eli, please retry ... "
    exit 1
fi

if ami --version | grep "$LATEST"; then
    echo "Latest ami already installed."
    exit 0
fi

# install ami
echo "Downloading ami $LATEST..."
if "$@" "https://github.com/alis-is/ami/releases/download/$LATEST/ami.lua" &&
    mv "$TMP_NAME" /usr/sbin/ami &&
    chmod +x /usr/sbin/ami; then
    echo "ami $LATEST successfuly installed."
else
    echo "ami installation failed!" 1>&2
    exit 1
fi
