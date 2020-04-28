FROM debian:latest
MAINTAINER BlackRose01<appdev.blackrose@gmail.com>

ENV OPENOLAT_VERSION 1428
ENV TOMCAT_VERSION 9.0.43
ENV INSTALL_DIR /opt/openolat
ENV DB_TYPE MYSQL
ENV DB_HOST 127.0.0.1
ENV DB_PORT 3306
ENV DB_NAME db
ENV DB_USER dbuser
ENV DB_PASS dbpass

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt install -y default-jre default-jre-headless unzip

RUN adduser --disabled-login --disabled-password --no-create-home openolat

RUN mkdir -p /opt/openolat
RUN mkdir /opt/openolat/bin /opt/openolat/conf /opt/openolat/lib /opt/openolat/logs /opt/openolat/olatdata /opt/openolat/run

ADD database/mysql.xml /tmp/mysql.xml
ADD database/postgresql.xml /tmp/postgresql.xml
ADD database/oracle.xml /tmp/oracle.xml
ADD database/sqlite.xml /tmp/sqlite.xml
ADD openolat.service /tmp/openolat.service
ADD server.xml /tmp/server.xml
ADD olat.local.properties /tmp/olat.local.properties

EXPOSE 8088/tcp

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
