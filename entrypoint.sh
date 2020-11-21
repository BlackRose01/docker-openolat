#!/bin/bash

# Set value for variables and normalize/create them
TOMCAT_URL="https://downloads.apache.org/tomcat/"
OPENOLAT_URL="https://www.openolat.com/fileadmin/downloads/releases/"
OPENOLAT_VERSION=$([[ ! -z $OPENOLAT_VERSION ]] && echo $OPENOLAT_VERSION || echo "latest")
TOMCAT_VERSION=$([[ ! -z $TOMCAT_VERSION ]] && echo $TOMCAT_VERSION || echo "latest")
TOMCAT_VERSION_MAJOR=$(echo $TOMCAT_VERSION | cut -d'.' -f 1)
DOMAINNAME=$([[ ! -z $DOMAINNAME ]] && echo $DOMAINNAME || echo "localhost")
INSTALL_DIR=$([[ ! -z $INSTALL_DIR ]] && echo $INSTALL_DIR || echo "/opt/openolat")
DB_TYPE=$([[ ! -z $DB_TYPE ]] && echo $(echo $DB_TYPE | tr '[:upper:]' '[:lower:]') || echo "sqlite")
DB_TYPE=$([[ ! -z $DB_HOST ]] && echo $DB_TYPE || echo "sqlite")
JAVA_DIR=$(find /usr/lib/jvm/ -maxdepth 1 -iname java-* -type d | head -n 1)
SMTP_HOST=$([[ ! -z $SMTP_HOST ]] && echo $SMTP_HOST || echo "disabled")
SMTP_PORT=$([[ ! -z $SMTP_PORT ]] && echo $SMTP_PORT || echo "25")
SMTP_USER=$([[ ! -z $SMTP_USER ]] && echo $SMTP_USER || echo "")
SMTP_PASS=$([[ ! -z $SMTP_PASS ]] && echo $SMTP_PASS || echo "")
SMTP_FROM=$([[ ! -z $SMTP_FROM ]] && echo $SMTP_FROM || echo "no-reply@your.domain")
SMTP_ADMIN=$([[ ! -z $SMTP_ADMIN ]] && echo $SMTP_ADMIN || echo "admin@your.domain")
SMTP_SSL=$([[ ! -z $SMTP_SSL ]] && echo $SMTP_SSL || echo "false")
SMTP_STARTTLS=$([[ ! -z $SMTP_STARTTLS ]] && echo $SMTP_STARTTLS || echo "false")
SMTP_CHECK_CERT=$([[ ! -z $SMTP_CHECK_CERT ]] && echo $SMTP_CHECK_CERT || echo "false")

# Download OpenOlat after check if exists
download_openolat() {
	OPENOLAT_URL="$1"
	OPENOLAT_VERSION=$2

	# if OPENOLAT_VERSION is latest then set variable to latest version number
	if [[ $OPENOLAT_VERSION -eq "latest" ]]; then
		OPENOLAT_VERSION=$(curl -s "$OPENOLAT_URL" | grep -Eoi "openolat_[0-9]{4,}.war" | uniq | sort -r | head -n 1 | grep -Eoi "[0-9]+")
		
		echo "Latest OpenOlat Version: $OPENOLAT_VERSION"
	fi

	# check if version exists and download it into /tmp folder
	if [[ $(curl -s "$OPENOLAT_URL" | grep -Eoi "openolat_[0-9]+.war" | uniq | grep "openolat_$OPENOLAT_VERSION" | wc -l) == 0 ]]; then
		echo "OpenOlat Version does not exists. Please change your required version."
                echo "Verify downloadable link @ $OPENOLAT_URL"
		return 1
	else
		wget "$OPENOLAT_URL/openolat_$OPENOLAT_VERSION.war" -O "/tmp/openolat.war" --unlink -q
	fi
	
	return 0
}

# Download Tomcat after check if exists
download_tomcat() {
	TOMCAT_URL="$1"
	TOMCAT_VERSION=$2
	TOMCAT_VERSION_MAJOR=$3

	# if TOMCAT_VERSION is latest then set variables TOMCAT_VERSION/TOMCAT_VERSION_MAJOR to latest version number
	if [[ "$TOMCAT_VERSION" = "latest" ]]; then
		TOMCAT_VERSION_MAJOR=$(curl -s "$TOMCAT_URL" | grep -Eoi "tomcat-[0-9]+" | uniq | cut -d'-' -f2 | sort -r -n | head -n 1)
		TOMCAT_VERSION=$(curl -s "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/" | grep -Poi "(?<=href=\")v10.*(?=/\")" | sort -r | head -n 1)
		
		echo "Latest Tomcat Version: $TOMCAT_VERSION"
	fi

	# check if Tomcat version exists and download it into /tmp folder
	if [[ $(curl -s "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/" -I | head -n 1 | grep -Eoi "[0-9]{3}") != 200 ]]; then
		echo "Cannot find major release from Tomcat Version: $TOMCAT_VERSION_MAJOR. So your passed TOMCAT_VERSION $TOMCAT_VERSION is wrong."
		return 1
	elif [[ $(curl -s "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/v$TOMCAT_VERSION/bin/" | grep -Eoi "apache-tomcat-$TOMCAT_VERSION.tar.gz" | uniq | wc -l) == 0 ]]; then
		echo "Cannot find tomcat release with Tomcat Version: $TOMCAT_VERSION. So your passes TOMCAT_VERSION is wrong."
		echo "Verify downloadable link @ $TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"
		return 1
	else
		wget "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" -O "/tmp/tomcat.tar.gz" --unlink -q
	fi
	
	return 0
}

# Get information from information file
get_configuration_information() {
	IFS="="

	while read -r name value
	do
		if [[ "$name" -eq "$2" ]]; then
			echo ${value//\"/}\"
			return 0
		fi
	done < "$1"

	return 1
}

# if OpenOlat was already installed
if [[ -e "$INSTALL_DIR/install_information" ]] && [[ "$(get_configuration_information "$INSTALL_DIR/install_information" "INSTALLED")" == "true" ]]; then
	# check if OpenOlat has to be update
	if [[ -z $OPENOLAT_UPDATE ]] && [[ $OPENOLAT_UPDATE == "true" ]]; then
		echo "Perform update/downgrade OpenOlat to version $OPENOLAT_VERSION"

		download_openolat "$OPENOLAT_URL" "$OPENOLAT_VERSION"

		# move OpenOlat configuration file; delete old data; unzip downloaded file to INSTALL_DIR; mv OpenOlat configuration file back
		mv "$INSTALL_DIR/webapp/WEB-INF/classes/serviceconfig/olat.properties" "$INSTALL_DIR/olat.properties"
		rm -r "$INSTALL_DIR/webapp"
		unzip -qq "/tmp/openolat.war" -d "$INSTALL_DIR"/webapp
		mv "$INSTALL_DIR/olat.properties" "$INSTALL_DIR/webapp/WEB-INF/classes/serviceconfig/olat.properties"
	fi

	# check if Tomcat has to be update
	if [[ -z $TOMCAT_UPDATE ]] && [[ $TOMCAT_UPDATE == "true" ]]; then
		echo "Perform update/downgrade Tomcat to version $TOMCAT_VERSION"
		
		download_tomcat "$TOMCAT_URL" "$TOMCAT_VERSION" "$TOMCAT_VERSION_MAJOR"
		
		# delete old tomcat version; unpack downloaded file; mv unpacked folder to INSTALL_DIR
		rm -r "$INSTALL_DIR/tomcat"
		tar xf "/tmp/tomcat.tar.gz" -C "$INSTALL_DIR"
		mv "$INSTALL_DIR"/apache-tomcat-* "$INSTALL_DIR"/tomcat
	fi
	
	# Update Domainname in Files and create Domainfolder for Catalina
	if [[ "$DOMAINNAME" -ne $(get_configuration_information "$INSTALL_DIR/install_information" "USED_DOMAINNAME") ]]; then
		echo "Change Domainname from $USED_DOMAINNAME to $DOMAINNAME"
		
		mkdir -p "$INSTALL_DIR/conf/Catalina/$DOMAINNAME"
		mv "$INSTALL_DIR/conf/Catalina/$USED_DOMAINNAME/ROOT.xml" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
		mkdir -p "$INSTALL_DIR/conf/Catalina/$USED_DOMAINNAME"
		
		sed -i -s "s+$USED_DOMAINNAME+$DOMAINNAME+g" "$INSTALL_DIR/conf/server.xml"
		sed -i -s "s+$USED_DOMAINNAME+$DOMAINNAME+g" "$INSTALL_DIR/lib/olat.local.properties"
	fi

	echo "Everything is already installed. Startup now!"
	
	# set environment variables
	export JAVA_HOME=$JAVA_DIR
	export JRE_HOME=$JAVA_DIR
	export CATALINA_BASE=$INSTALL_DIR
	export CATALINA_HOME=$INSTALL_DIR/tomcat

	# Start OpenOlat
	/bin/sh /start run >> "$INSTALL_DIR/logs/stdout.log"
	
	exit 0
fi

# create necessary folders
echo "Create necessary folders for OpenOlat in: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir "$INSTALL_DIR/bin" "$INSTALL_DIR/conf" "$INSTALL_DIR/lib" "$INSTALL_DIR/logs" "$INSTALL_DIR/olatdata" "$INSTALL_DIR/run"
mkdir -p "$INSTALL_DIR/conf/Catalina/$DOMAINNAME"

# download OpenOlat
echo "Download OpenOlat Version: $OPENOLAT_VERSION"
download_openolat "$OPENOLAT_URL" "$OPENOLAT_VERSION"

if [[ $? == 1 ]]; then
	exit 1
fi

# Download Tomcat
echo "Download Tomcat Version: $TOMCAT_VERSION"
download_tomcat "$TOMCAT_URL" "$TOMCAT_VERSION" "$TOMCAT_VERSION_MAJOR"

if [[ $? == 1 ]]; then
	exit 1
fi

# Process downloaded files
echo "Unpack downloaded files to installation directory (this can be take some time)"
tar xf "/tmp/tomcat.tar.gz" -C "$INSTALL_DIR"
mv "$INSTALL_DIR"/apache-tomcat-* "$INSTALL_DIR"/tomcat

unzip -qq "/tmp/openolat.war" -d "$INSTALL_DIR"/webapp

# Symlink tomcat files to created folders
echo "Create necessary Symlinks/Move files"
ln -s "$INSTALL_DIR/tomcat/bin/catalina.sh" "/start"
ln -s "$INSTALL_DIR/tomcat/bin/startup.sh" "$INSTALL_DIR/start"
ln -s "$INSTALL_DIR/tomcat/bin/shutdown.sh" "$INSTALL_DIR/stop"
ln -s "$INSTALL_DIR/tomcat/bin/catalina.sh" "$INSTALL_DIR/bin/catalina.sh"
ln -s "$INSTALL_DIR/tomcat/bin/catalina.sh" "$INSTALL_DIR/conf/catalina.sh"
ln -s "$INSTALL_DIR/tomcat/conf/web.xml" "$INSTALL_DIR/conf/web.xml"

mv "/tmp/server.xml" "$INSTALL_DIR/conf/server.xml"
mv "/tmp/log4j2.xml" "$INSTALL_DIR/lib/log4j2.xml"
mv "/tmp/olat.local.properties" "$INSTALL_DIR/lib/olat.local.properties"

# Database configuration
echo "Create database configuration for OpenOlat"
case $DB_TYPE in
	"oracle")
		DB_PORT=$([[ ! -z $DB_PORT ]] && echo $DB_PORT || echo "1521")
		
		mv "/tmp/oracle.xml" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
		;;
	"mysql")
		DB_PORT=$([[ ! -z $DB_PORT ]] && echo $DB_PORT || echo "3306")
		
		mv "/tmp/mysql.xml" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
		;;
	"postgresql")
		DB_PORT=$([[ ! -z $DB_PORT ]] && echo $DB_PORT || echo "5432")
		
		mv "/tmp/postgresql.xml" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
		;;
	*)
		mv "/tmp/sqlite.xml" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
		;;
esac

sed -i -s "s+_INSTALL_DIR_+$INSTALL_DIR+g" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
sed -i -s "s+_DB_HOST_+$DB_HOST+g" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
sed -i -s "s+_DB_PORT_+$DB_PORT+g" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
sed -i -s "s+_DB_NAME_+$DB_NAME+g" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
sed -i -s "s+_DB_USER_+$DB_USER+g" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"
sed -i -s "s+_DB_PASS_+$DB_PASS+g" "$INSTALL_DIR/conf/Catalina/$DOMAINNAME/ROOT.xml"

echo "Update OpenOlat configuration file"
sed -i -s "s+_INSTALL_DIR_+$INSTALL_DIR+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_DOMAINNAME_+$DOMAINNAME+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_DB_TYPE_+$DB_TYPE+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_DB_NAME_+$DB_NAME+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_DB_USER_+$DB_USER+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_DB_PASS_+$DB_PASS+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_HOST_+$SMTP_HOST+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_PORT_+$SMTP_PORT+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_USER_+$SMTP_USER+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_PASS_+$SMTP_PASS+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_FROM_+$SMTP_FROM+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_ADMIN_+$SMTP_ADMIN+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_SSL_+$SMTP_SSL+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_STARTTLS_+$SMTP_STARTTLS+g" "$INSTALL_DIR/lib/olat.local.properties"
sed -i -s "s+_SMTP_CHECK_CERT_+$SMTP_CHECK_CERT+g" "$INSTALL_DIR/lib/olat.local.properties"

sed -i -s "s+_INSTALL_DIR_+$INSTALL_DIR+g" "$INSTALL_DIR/lib/log4j2.xml"

sed -i -s "s+_DOMAINNAME_+$DOMAINNAME+g" "$INSTALL_DIR/conf/server.xml"

# create setenv.sh file with Catalina/Java information
echo "Create environment file for tomcat"
touch "$INSTALL_DIR/bin/setenv.sh"

echo "CATALINA_HOME=$INSTALL_DIR/tomcat" >> "$INSTALL_DIR/bin/setenv.sh"
echo "CATALINA_BASE=$INSTALL_DIR" >> "$INSTALL_DIR/bin/setenv.sh"
echo "CATALINA_PID=$INSTALL_DIR/run/openolat.pid" >> "$INSTALL_DIR/bin/setenv.sh"
echo "CATALINA_TMPDIR=/tmp/openolat" >> "$INSTALL_DIR/bin/setenv.sh"
echo "JRE_HOME=$JAVA_DIR" >> "$INSTALL_DIR/bin/setenv.sh"
echo "" >> "$INSTALL_DIR/bin/setenv.sh"
echo 'mkdir -p $CATALINA_TMPDIR' >> "$INSTALL_DIR/bin/setenv.sh"

# set global variables
echo "Set global environment variables"
export JAVA_HOME=$JAVA_DIR
export JRE_HOME=$JAVA_DIR
export CATALINA_BASE=$INSTALL_DIR
export CATALINA_HOME=$INSTALL_DIR/tomcat

# delete not necessary files
echo "Clean up"
rm -r /tmp/*.xml
rm -r /tmp/openolat.war
rm -r /tmp/tomcat.tar.gz
rm -r /tmp/*.service

# create install_information file and save configuration information in
echo "Write installation information"
touch "$INSTALL_DIR/install_information"

echo "INSTALLED=true" >> "$INSTALL_DIR/install_information"
echo "INSTALLED_OPENOLAT_VERSION=$OPENOLAT_VERSION" >> "$INSTALL_DIR/install_information"
echo "INSTALLED_TOMCAT_VERSION=$TOMCAT_VERSION" >> "$INSTALL_DIR/install_information"
echo "USED_DOMAINNAME=$DOMAINNAME" >> "$INSTALL_DIR/install_information"

# Start openolat
echo "Start OpenOlat"
/bin/sh /start run >> "$INSTALL_DIR/logs/stdout.log"

exit 0
