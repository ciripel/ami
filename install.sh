#!/bin/sh

TMP_NAME="./$(head -n 1 -c 32 /dev/urandom | tr -dc 'a-zA-Z0-9'| fold -w 32)"

if which curl >/dev/null; then
    if curl --help  2>&1 | grep "--progress-bar" > /dev/null; then 
        PROGRESS="--progress-bar"
    fi

    set -- curl -L $PROGRESS -o "$TMP_NAME"
    LATEST=$(curl -sL https://api.github.com/repos/alis-is/ami/releases/latest | grep tag_name | sed 's/  "tag_name": "//g' | sed 's/",//g')
else
    if wget --help  2>&1 | grep "--show-progress" > /dev/null; then 
        PROGRESS="--show-progress"
    fi
    set -- wget -q $PROGRESS -O "$TMP_NAME"
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
    echo "Latest ami already available."
    exit 0
fi

# install ami
echo "Downloading ami $LATEST..."
if "$@" "https://github.com/alis-is/ami/releases/download/$LATEST/ami.lua" &&
    cp "$TMP_NAME" /usr/sbin/eli &&
    chmod +x /usr/sbin/ami; then
    rm "$TMP_NAME"
    echo "ami $LATEST successfuly installed."
else
    rm "$TMP_NAME"
    echo "ami installation failed!" 1>&2
    exit 1
fi
