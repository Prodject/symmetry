#!/usr/bin/env bash
RELEASE=3.6.1

# install dependencies
sudo apt install libbz2-dev liblzma-dev libsqlite3-dev libncurses5-dev libgdbm-dev zlib1g-dev libreadline-dev libssl-dev tk-dev -y

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [[ -z "$RELEASE" ]]; then
	# download and build Python
	mkdir -p $HOME/python3
	cd ~/python3
	wget https://www.python.org/ftp/python/$RELEASE/Python-$RELEASE.tar.xz
	tar xvf Python-$RELEASE.tar.xz
	cd Python-$RELEASE
	./configure
	make
	sudo make install
	sudo rm -rf $HOME/python3/Python-$RELEASE
	cd ~
fi

unset RELEASE