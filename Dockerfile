FROM redhat-openjdk-18/openjdk18-openshift
LABEL maintainer="Ancert Sistemas"

WORKDIR /usr/local

ENV LIFERAY_HOME=/usr/local//liferay-ce-portal-7.1.0-ga1/
ENV LIFERAY_TOMCAT_URL=https://cdn.lfrs.sl/releases.liferay.com/portal/7.1.0-ga1/liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip
ENV CATALINA_HOME=$LIFERAY_HOME/tomcat-8.0.32
ENV PATH=$CATALINA_HOME/bin:$PATH

# DEV
ENV JMXREMOTE_PORT=9999
ENV JPDA_TRANSPORT=dt_socket
ENV JPDA_ADDRESS=8000

USER root

COPY ./config/yum.conf /etc/
COPY ./config/yum.repos.d/* /etc/yum.repos.d/
COPY ./config/default_locale /etc/default/locale
COPY ./config/default_bash_profile /tmp/default_bash_profile

RUN yum install -y \
		unzip \
		curl \
		telnet \
	&& yum -y clean all 

RUN useradd -ms /bin/bash liferay && \
	set -x && \
	mkdir -p $LIFERAY_HOME \
	curl -fSL "$LIFERAY_TOMCAT_URL" -o liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip && \
	unzip liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip && \
	rm liferay-ce-portal-tomcat-7.1.0-ga1-20180703012531655.zip && \
	rm -rf $CATALINA_HOME/work/* && \
	mkdir -p $LIFERAY_HOME/data/document_library && \
	mkdir -p $LIFERAY_HOME/data/elasticsearch/indices
	
RUN mkdir -p /tmp/themes && chown -R liferay:liferay /tmp/themes

COPY ./config/setenv.sh $CATALINA_HOME/bin/setenv.sh

RUN chown -R liferay:liferay $LIFERAY_HOME

USER liferay

# PRO
EXPOSE 8080/tcp
ENTRYPOINT ["catalina.sh", "run"]

# DEV
# EXPOSE 8000/tcp 9999/tcp 11311/tcp
# ENTRYPOINT ["catalina.sh", "jpda", "run"]

