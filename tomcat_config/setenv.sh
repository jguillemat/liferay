CATALINA_OUT=$CATALINA_HOME/logs/catalina-$HOSTNAME.out

CATALINA_OPTS="$CATALINA_OPTS -Dfile.encoding=UTF8 -Dcompany-id-properties=true -Djava.net.preferIPv4Stack=true -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false -Duser.timezone=CET -Xms2048m -Xmx2048m -XX:MaxPermSize=512m  -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8686 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dhttp.proxyHost=193.16.43.201 -Dhttp.proxyPort=3127 -Dhttp.nonProxyHosts='localhost|rest-services|oauth-services|internal_http|des.www.ancert.com|des.agn.notariado.org'"

