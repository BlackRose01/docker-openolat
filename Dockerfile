FROM debian:latest
MAINTAINER BlackRose01<appdev.blackrose@gmail.com>

ENV DOMAINNAME localhost
ENV OPENOLAT_VERSION 1428
ENV OPENOLAT_UPDATE false
ENV TOMCAT_VERSION 9.0.34
ENV TOMCAT_UPDATE false
ENV INSTALL_DIR /opt/openolat

ENV DB_TYPE MYSQL
ENV DB_HOST 192.168.0.2
ENV DB_PORT 3307
ENV DB_NAME test-oo
ENV DB_USER test-oo
ENV DB_PASS test-oo

#ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
#ENV CATALINA_HOME /opt/openolat/tomcat
#ENV CATALINA_BASE /opt/openolat
#ENV JRE_HOME /usr/lib/jvm/java-11-openjdk-amd64

COPY database/mysql.xml /tmp/mysql.xml
COPY database/postgresql.xml /tmp/postgresql.xml
COPY database/oracle.xml /tmp/oracle.xml
COPY database/sqlite.xml /tmp/sqlite.xml
COPY server.xml /tmp/server.xml
COPY olat.local.properties /tmp/olat.local.properties
COPY log4j2.xml /tmp/log4j2.xml
COPY entrypoint.sh /entrypoint.sh

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt install -y default-jre default-jre-headless unzip curl wget

#RUN export JAVA_HOME=$(find /usr/lib/jvm/ -maxdepth 1 -iname java-* -type d | head -n 1)
#RUN export JRE_HOME=$(find /usr/lib/jvm/ -maxdepth 1 -iname java-* -type d | head -n 1)
#RUN export CATALINA_HOME=$INSTALL_DIR/tomcat
#RUN export CATALINA_BASE=$INSTALL_DIR

EXPOSE 8088/tcp

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "/entrypoint.sh"]

#ENTRYPOINT ["/bin/bash"]
#CMD ["/entrypoint.sh"]
