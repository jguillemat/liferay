#!/bin/bash

# https://github.com/mdelapenya/docker-liferay-portal/edit/master/entrypoint.sh

set -o errexit

main() {
  check_env_vars
  show_motd
  prepare_liferay_persistent_data_dirs
  prepare_liferay_portal_properties
  prepare_liferay_tomcat_config
  run_portal "$@"
}

function show_motd() {
  echo "Starting Liferay 7.1 instance.
  LIFERAY_HOME: $LIFERAY_HOME
  POSTGRESQL_USER: $POSTGRESQL_USER
  runAS: `id -u`
  "
}

function usage() {
  if [ $# == 1 ]; then
    echo >&2 "error: $1"
  fi

psql_identifier_regex='^[a-zA-Z_][a-zA-Z0-9_]*$'
psql_password_regex='^[a-zA-Z0-9_~!@#$%^&*()-=<>,.?;:|]+$'

  cat >&2 <<EOF
For Liferay container run, you must either specify the following environment
variables:
  POSTGRESQL_USER (regex: '$psql_identifier_regex')
  POSTGRESQL_PASSWORD (regex: '$psql_password_regex')
  POSTGRESQL_SERVICE_HOST 
  POSTGRESQL_SERVICE_PORT 
  POSTGRESQL_DATABASE 
Or both.
EOF
  exit 1
}

function check_env_vars() {

  if [[ -v POSTGRESQL_USER || -v POSTGRESQL_PASSWORD || -v POSTGRESQL_SERVICE_HOST || -v POSTGRESQL_SERVICE_PORT || -v POSTGRESQL_DATABASE ]]; then
    # one var means all three must be specified
    [[ -v POSTGRESQL_USER && -v POSTGRESQL_PASSWORD ]] || usage
    [[ "$POSTGRESQL_USER"     =~ $psql_identifier_regex ]] || usage
    [[ "$POSTGRESQL_PASSWORD" =~ $psql_password_regex   ]] || usage
    [ ${#POSTGRESQL_USER} -le 63 ] || usage "PostgreSQL username too long (maximum 63 characters)"

  fi
 
}


function prepare_liferay_portal_properties() {
  if [[ ! -f "$LIFERAY_TEMPORAL_DIR/portal-ext.properties" ]]; then

    echo "No 'configs/portal-ext.properties' file found.
  If you wish to use a custom properties file make sure
  you include a 'configs/portal-ext.properties' file in the 
  root of your project.

  Continuing.
  "
    return 0
  fi

  echo "Portal properties (portal-ext.properties) file found."

  cp -r $LIFERAY_TEMPORAL_DIR/portal-ext.properties $LIFERAY_HOME/portal-ext.properties

  echo " Continuing."
}

function prepare_liferay_tomcat_config() {
  
  echo "Configuring Tomcat server.xml ..."

  cp $LIFERAY_HOME/server.xml_template  $CATALINA_HOME/conf/server.xml

  sed -i 's/POSTGRESQL_USER/'"$POSTGRESQL_USER"'/g' $CATALINA_HOME/conf/server.xml
  sed -i 's/POSTGRESQL_PASSWORD/'"$POSTGRESQL_PASSWORD"'/g' $CATALINA_HOME/conf/server.xml
  sed -i 's/POSTGRESQL_SERVICE_HOST/'"$POSTGRESQL_SERVICE_HOST"'/g' $CATALINA_HOME/conf/server.xml
  sed -i 's/POSTGRESQL_SERVICE_PORT/'"$POSTGRESQL_SERVICE_PORT"'/g' $CATALINA_HOME/conf/server.xml
  sed -i 's/POSTGRESQL_DATABASE/'"$POSTGRESQL_DATABASE"'/g' $CATALINA_HOME/conf/server.xml

  echo "Continuing."
}


function prepare_liferay_persistent_data_dirs() {
  
  echo "Checking Liferay data dirs ..."

  if [[ ! -f "$LIFERAY_HOME/data/hypersonic" ]]; then
    echo "No data in $LIFERAY_HOME/data'  found. Iniitalitzating data..." 
    rsync -a --ignore-existing /tmp/data/* $LIFERAY_HOME/data/
  fi

  if [[ ! -f "$LIFERAY_HOME/osgi/hypersonic" ]]; then
    echo "No data in $LIFERAY_HOME/osgi'  found. Iniitalitzating osgi..." 
    rsync -a --ignore-existing /tmp/osgi/* $LIFERAY_HOME/osgi/
  fi

  if [[ ! -f "$LIFERAY_HOME/tomcat-9.0.6/" ]]; then
    echo "No data in $LIFERAY_HOME/tomcat-9.0.6'  found. Iniitalitzating data..." 
    rsync -a --ignore-existing /tmp/tomcat-9.0.6/* $LIFERAY_HOME/tomcat-9.0.6/
  fi

}

function run_portal() {
  set -e
  cd $CATALINA_HOME
  ./bin/catalina.sh run
}

main "$@"



