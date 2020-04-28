# docker-openolat
Create a Dockerimage for OpenOlat

## Environmental Variables
| **Variable** | **Meaning** | **Default Value** |
|---|---|---|
| OPENOLAT_VERSION | Version of OpenOlat which will be downloaded | latest |
| TOMCAT_VERSION | Version of Tomcat Server which will be downloaded | latest |
| INSTALL_DIR | Directory of Server installation | /opt/openolat |
| DB_TYPE | Database type (sqlite, mysql, postgresql, oracle) | sqlite |
| DB_HOST | Database Server IP/Name (ignored by SQLite) | 127.0.0.1 |
| DB_PORT | Database Server IP/Name (ignored by SQLite) | 3306 |
| DB_NAME | Database Server IP/Name (ignored by SQLite) | db |
| DB_USER | Database Server IP/Name (ignored by SQLite) | dbuser |
| DB_PASS | Database Server IP/Name (ignored by SQLite) | dbpass |

## Ports
This image only needs Port 8088 TCP for HTTP.

## Necessary files
The following files are relevant to control OpenOlat.
- $INSTALL_DIR/lib/olat.local.properties
- $INSTALL_DIR/webapp/WEB-INF/classes/serviceconfig/olat.properties
