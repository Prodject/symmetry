#!/usr/bin/env bash

_install_subsonic() {
	local env_line="JAVA_HOME=/usr/lib/jvm/jdk-8-oracle-arm-vfp-hflt\n";
	local env_file="/etc/environment";
	local subsonic_version="6.1.1";
	sudo apt-get install oracle-java8-jdk -y;

	local jvm=$(java --version);
	if [ ! "$jvm" =~ "java version \"1.8.0\"" ]; then
		if grep -Fxq "$env_line" "$env_file"; then
			echo "skipping '${env_line}'";
		else
			echo "$env_line" >> "$env_file";
		fi
	fi
	wget -P "$HOME/" –O "subsonic-${subsonic_version}.deb" "https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-${subsonic_version}.deb";
	sudo dpkg -i "$HOME/subsonic-${subsonic_version}.deb";

	rm "$HOME/subsonic-${subsonic_version}.deb";

	sudo /etc/init.d/subsonic stop;

	sudo adduser subsonic;
	sudo adduser subsonic audio;
	sudo sed -e 's|SUBSONIC_USER=root|SUBSONIC_USER=subsonic|' /etc/default/subsonic > $HOME/subsonic.tmp;
	sudo mv $HOME/subsonic.tmp /etc/default/subsonic;
	sudo chown subsonic:subsonic /var/subsonic -Rv;

	 # install nginx? for reverse proxy?

	sudo /etc/init.d/subsonic start
}

_install_subsonic;
