FROM redhat-openjdk-18/openjdk18-openshift
LABEL maintainer="Ancert Sistemas"

# ref: https://github.com/mdelapenya/docker-liferay-portal/blob/master/Dockerfile

WORKDIR /usr/local

ENV LIFERAY_HOME=/usr/local//liferay-ce-portal-7.1.0-ga1/
ENV LIFERAY_TOMCAT_URL=https://cdn.lfrs.sl/releases.liferay.com/portal/7.1.0-ga1/liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip
ENV LIFERAY_SHARED=/storage/liferay
ENV LIFERAY_CONFIG_DIR=/tmp/liferay/configs
ENV LIFERAY_DEPLOY_DIR=/tmp/liferay/deploy
ENV CATALINA_HOME=$LIFERAY_HOME/tomcat-9.0.6
ENV PATH=$CATALINA_HOME/bin:$PATH

# DEBUG mode
ENV JMXREMOTE_PORT=9999
ENV JPDA_TRANSPORT=dt_socket
ENV JPDA_ADDRESS=8000

USER root

# COPY ./config/yum.conf /etc/
# COPY ./config/yum.repos.d/* /etc/yum.repos.d/
# RUN yum install -y \
# 		unzip \
# 		curl \
# 		telnet \
# 	&& yum -y clean all 

RUN groupadd -g 1111 -r liferay && \
	useradd -g liferay -ms /bin/bash -u 1111 liferay && \
	set -x && \
	mkdir -p $LIFERAY_HOME && \
	curl "$LIFERAY_TOMCAT_URL" --output liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip && \
	unzip liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip && \
	rm liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip && \
	rm -rf $CATALINA_HOME/temp/* && \
	rm -rf $CATALINA_HOME/work/* && \
	mkdir -p $LIFERAY_HOME/data/document_library && \
	mkdir -p $LIFERAY_HOME/data/elasticsearch6/indices
	
COPY ./config/default_locale /etc/default/locale
COPY ./config/default_bash_profile /tmp/default_bash_profile
COPY ./config/setenv.sh $CATALINA_HOME/bin/setenv.sh
COPY server.xml_template $LIFERAY_HOME/server.xml_template
COPY ./run-liferay.sh /usr/local/bin

RUN chown -R liferay:liferay $LIFERAY_HOME /usr/local/bin/run-liferay.sh
RUN chmod +x /usr/local/bin/run-liferay.sh
RUN chmod +x $CATALINA_HOME/bin/catalina.sh
RUN chmod 744 $LIFERAY_HOME/server.xml_template

USER 1111

# NORMAL mode
EXPOSE 8080/tcp
EXPOSE 9000/tcp
# ENTRYPOINT ["catalina.sh", "run"]

# Custom Entrypoint
ENTRYPOINT ["run-liferay.sh"]

# DEBUG mode
# EXPOSE 11311/tcp
# ENTRYPOINT ["catalina.sh", "jpda", "run"]

