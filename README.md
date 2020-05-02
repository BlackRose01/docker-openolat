# docker-openolat
Creates a Container for OpenOlat

## Prerequisite
If you want to run your OpenOlat with a remote database (MySQL/MariaDB, Oracle, PostgreSQL) then you have to create the database with tables and keys first. The 
necessary SQL-file can you find here:
- $INSTALL_DIR/webapp/WEB-INF/classes/database/$DB_TYPE/setupDatasbe.sql

You can also find the file in the OpenOlat WAR-file when you unzip it.

## Environmental Variables
| **Variable** | **Meaning** | **Possible Values** | **Default Value** |
|---|---|---|---|
| DOMAINNAME | Defines the name of used domain | IP or Hostname | localhost |
| OPENOLAT_VERSION | Version of OpenOlat which will be downloaded | * | latest |
| OPENOLAT_UPDATE | Defines if OpenOlat should update | true, false | false |
| TOMCAT_VERSION | Version of Tomcat Server which will be downloaded | * |  latest |
| TOMCAT_UPDATE | Defines if Tomcat should update | true, false | false |
| INSTALL_DIR | Directory of Server installation | Path in Filesystem | /opt/openolat |
| DB_TYPE | Database type (sqlite, mysql, postgresql, oracle) | sqlite, mysql, postgresql, oracle | sqlite |
| DB_HOST | Database Server IP/Name (ignored by SQLite) | 0.0.0.0 - 255.255.255.255 or Hostname | 127.0.0.1 |
| DB_PORT | Database Server IP/Name (ignored by SQLite) | * | 3306 |
| DB_NAME | Database Server IP/Name (ignored by SQLite) | * | db |
| DB_USER | Database Server IP/Name (ignored by SQLite) | * | dbuser |
| DB_PASS | Database Server IP/Name (ignored by SQLite) | * | dbpass |
| SMTP_HOST | Host of your SMTP Server | IP or Hostname | disabled |
| SMTP_PORT | Port of your SMTP Server | * | 25 |
| SMTP_USER | Username for SMTP | * | (empty) |
| SMTP_PASS | Password for SMTP User | * | (empty) |
| STMP_FROM | From Mail Adress | * | no-reply@your.domain |
| SMTP_ADMIN | Admin Mail Adress | * | admin@your.domain |
| SMTP_SSL | Use SSL encryption | true, false | false |
| SMTP_STARTTLS | Use Starttls encryption | true, false | false |
| SMTP_CHECK_CERT | Check Server Certificate | true, false | false |

* means everything

## Ports
This image only needs Port 8088 TCP for HTTP.

## Necessary files
The following files are relevant to control OpenOlat.
- $INSTALL_DIR/lib/olat.local.properties
- $INSTALL_DIR/webapp/WEB-INF/classes/serviceconfig/olat.properties

The file "olat.local.properties" overwrite properties from olat.properties.

## Volumes
The datadictionary of OpenOlat you can find in $INSTALL_DIR/olatdata

## How to update/downgrade OpenOlat or Tomcat
1) Enter new Version of OpenOlat or Tomcat into environment variable
2) set environment variable OPENOLAT_UPDATE and/or TOMCAT_UPDATE to value true
3) restart docker container

## Note
* The CPU usage will be very high on start

## Sources
[OpenOlat Adminwiki](https://www.openolat.com/fileadmin/adminwiki/_START_.html) \
[Docker References Dockerfile](https://docs.docker.com/engine/reference/builder/) \
[GitHub Repository OpenOlat](https://github.com/OpenOLAT/OpenOLAT) \
[Sample Configuration File](https://github.com/klemens/openolat/blob/master/olat.local.properties.sample) \
[Sample Mail Configuration](https://www.linuxforen.de/forums/showthread.php?280359-openOLAT-auf-tomcat-verschickt-keine-Mails&styleid=4)
