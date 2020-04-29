#!/bin/bash

TOMCAT_URL="https://downloads.apache.org/tomcat/"
OPENOLAT_URL="https://www.openolat.com/fileadmin/downloads/releases/"
OPENOLAT_VERSION=$([[ ! -z $OPENOLAT_VERSION ]] && echo $OPENOLAT_VERSION || echo "latest")
TOMCAT_VERSION=$([[ ! -z $TOMCAT_VERSION ]] && echo $TOMCAT_VERSION || echo "latest")
TOMCAT_VERSION_MAJOR=$(echo $TOMCAT_VERSION | cut -d'.' -f 1)
INSTALL_DIR=$([[ ! -z $INSTALL_DIR ]] && echo $INSTALL_DIR || echo "/opt/openolat")
DB_TYPE=$([[ ! -z $DB_TYPE ]] && echo $(echo $DB_TYPE | tr '[:upper:]' '[:lower:]') || echo "sqlite")
DB_TYPE=$([[ ! -z $DB_HOST ]] && echo $DB_TYPE || echo "sqlite")
JAVA_DIR=$(find /usr/lib/jvm/ -maxdepth 1 -iname java-* -type d | head -n 1)

echo "Create necessary folders for OpenOlat in: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir "$INSTALL_DIR/bin" "$INSTALL_DIR/conf" "$INSTALL_DIR/lib" "$INSTALL_DIR/logs" "$INSTALL_DIR/olatdata" "$INSTALL_DIR/run"
mkdir -p "$INSTALL_DIR/conf/Catalina/localhost"

echo "Download OpenOlat Version: $OPENOLAT_VERSION"
if [[ $OPENOLAT_VERSION -eq "latest" ]]; then
	OPENOLAT_VERSION=$(curl -s $OPENOLAT_URL | grep -Eoi "openolat_[0-9]{4,}.war" | uniq | sort -r | head -n 1 | grep -Eoi "[0-9]+")
	
	echo "Download OpenOlat version: $OPENOLAT_VERSION"
	wget "$OPENOLAT_URL/openolat_$OPENOLAT_VERSION.war" -O /tmp/openolat.war --unlink
elif [[ $(curl -s $OPENOLAT_URL | grep -Eoi "openolat_[0-9]+.war" | uniq | grep "openolat_$OPENOLAT_VERSION" | wc -l) == 0 ]]; then
	echo "OpenOlat Version does not exists. Please change your required Version."
	exit 1
else
	echo "Download OpenOlat version: $OPENOLAT_VERSION"
	wget "$OPENOLAT_URL/openolat_$OPENOLAT_VERSION.war" -O "/tmp/openolat.war" --unlink
fi

echo "Download Tomcat Version: $TOMCAT_VERSION"
if [[ $TOMCAT_VERSION = "latest" ]]; then
	echo "Later..."
elif [[ $(curl -s "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/" -I | head -n 1 | grep -Eoi "[0-9]{3}") != 200 ]]; then
	echo "Cannot find major release from Tomcat Version: $TOMCAT_VERSION_MAJOR. So your passed TOMCAT_VERSION $TOMCAT_VERSION is wrong."
	exit 1
elif [[ $(curl -s "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/v$TOMCAT_VERSION/bin/" | grep -Eoi "apache-tomcat-$TOMCAT_VERSION.tar.gz" | uniq | wc -l) == 0 ]]; then
	echo "Cannot find tomcat release with Tomcat Version: $TOMCAT_VERSION. So your passes TOMCAT_VERSION is wrong."
	exit 1
else
	echo "Download Tomcat version: $TOMCAT_VERSION"
	wget "$TOMCAT_URL/tomcat-$TOMCAT_VERSION_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" -O "/tmp/tomcat.tar.gz" --unlink
fi

echo "Unpack downloaded files to installation directory"
tar xf "/tmp/tomcat.tar.gz" -C "$INSTALL_DIR"
mv "$INSTALL_DIR/apache-tomcat-*" -t "$INSTALL_DIR/tomcat"

unzip -f -qq "/tmp/openolat.war" -d "$INSTALL_DIR/webapp"

echo "Create necessary Symlinks/Move files"
ln -s "$INSTALL_DIR/tomcat/bin/startup.sh" "$INSTALL_DIR/start"
ln -s "$INSTALL_DIR/tomcat/bin/shutdown.sh" "$INSTALL_DIR/stop"
ln -s "$INSTALL_DIR/tomcat/bin/catalina.sh" "$INSTALL_DIR/bin/catalina.sh"
ln -s "$INSTALL_DIR/tomcat/bin/catalina.sh" "$INSTALL_DIR/conf/catalina.sh"
ln -s "$INSTALL_DIR/tomcat/conf/web.xml" "$INSTALL_DIR/conf/web.xml"

mv "/tmp/server.xml" "$INSTALL_DIR/conf/server.xml"
mv "/tmp/olat.local.properties" "$INSTALL_DIR/lib/olat.local.properties"

echo "Create database configuration for OpenOlat"
case $DB_TYPE in
	"oracle")
		DB_PORT=$([[ ! -z $DB_PORT ]] && echo $DB_PORT || echo "1521")
		
		mv "/tmp/oracle.xml" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
		;;
	"mysql")
		DB_PORT=$([[ ! -z $DB_PORT ]] && echo $DB_PORT || echo "3306")
		
		mv "/tmp/mysql.xml" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
		;;
	"postgresql")
		DB_PORT=$([[ ! -z $DB_PORT ]] && echo $DB_PORT || echo "5432")
		
		mv "/tmp/postgresql.xml" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
		;;
	*)
		mv "/tmp/sqlite.xml" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
		;;
esac

sed "s/_INSTALL_DIR_/$INSTALL_DIR/g" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml" > "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
sed "s/_DB_HOST_/$DB_HOST/g" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml" > "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
sed "s/_DB_PORT_/$DB_PORT/g" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml" > "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
sed "s/_DB_NAME_/$DB_NAME/g" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml" > "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
sed "s/_DB_USER_/$DB_USER/g" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml" > "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"
sed "s/_DB_PASS_/$DB_PASS/g" "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml" > "$INSTALL_DIR/conf/Catalina/localhost/openolat.xml"

echo "Update OpenOlat configuration file"
sed "s/_INSTALL_DIR_/$INSTALL_DIR/g" "$INSTALL_DIR/lib/olat.local.properties" > "$INSTALL_DIR/lib/olat.local.properties"

echo "Create environment file"
touch "$INSTALL_DIR/bin/setenv.sh"

echo "CATALINA_HOME=$INSTALL_DIR/tomcat" >> "$INSTALL_DIR/bin/setenv.sh"
echo "CATALINA_BASE=$INSTALL_DIR" >> "$INSTALL_DIR/bin/setenv.sh"
echo "CATALINA_PID=$INSTALL_DIR/run/openolat.pid" >> "$INSTALL_DIR/bin/setenv.sh"
echo "CATALINA_TMPDIR=$JAVA_DIR" >> "$INSTALL_DIR/bin/setenv.sh"
echo "JRE_HOME=/tmp/openolat" >> "$INSTALL_DIR/bin/setenv.sh"
echo "" >> "$INSTALL_DIR/bin/setenv.sh"
echo 'mkdir -p $CATALINA_TMPDIR' >> "$INSTALL_DIR/bin/setenv.sh"

echo "Set user permissions for user openolat to $INSTALL_DIR"
chown openolat:openolat "$INSTALL_DIR"

#echo "Create and activate OpenOlat Service"
#mv "/tmp/openolat.service" "/etc/systemd/system/openolat.service"

echo "Clean up"
rm -r /tmp/*.xml

#systemctl enable openolat.service
#systemctl daemon-reload
#systemctl start openolat.service

/bin/sh $INSTALL_DIR/start

exit 0
