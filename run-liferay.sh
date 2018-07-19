#!/bin/bash

# https://github.com/mdelapenya/docker-liferay-portal/edit/master/entrypoint.sh

set -o errexit

main() {
  check_env_vars
  show_motd
  prepare_liferay_portal_properties
  prepare_liferay_tomcat_config
  run_portal "$@"
}

show_motd() {
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
Or both.
EOF
  exit 1
}

function check_env_vars() {

  if [[ -v POSTGRESQL_USER || -v POSTGRESQL_PASSWORD ]]; then
    # one var means all three must be specified
    [[ -v POSTGRESQL_USER && -v POSTGRESQL_PASSWORD ]] || usage
    [[ "$POSTGRESQL_USER"     =~ $psql_identifier_regex ]] || usage
    [[ "$POSTGRESQL_PASSWORD" =~ $psql_password_regex   ]] || usage

    [ ${#POSTGRESQL_USER} -le 63 ] || usage "PostgreSQL username too long (maximum 63 characters)"
    postinitdb_actions+=",simple_db"
  fi

  case "$postinitdb_actions" in
    ,simple_db,admin_pass) ;;
    ,migration|,simple_db|,admin_pass) ;;
    *) usage ;;
  esac
}


prepare_liferay_portal_properties() {
  if [[ ! -f "$LIFERAY_CONFIG_DIR/portal-ext.properties" ]]; then
    echo "No 'configs/portal-ext.properties' file found.
  If you wish to use a custom properties file make sure
  you include a 'configs/portal-ext.properties' file in the 
  root of your project.

  Continuing.
  "
    return 0
  fi

  echo "Portal properties (portal-ext.properties) file found.
  "

  cp -r $LIFERAY_CONFIG_DIR/portal-ext.properties $LIFERAY_HOME/portal-ext.properties

  echo "
  Continuing.
  "
}

prepare_liferay_tomcat_config() {
  
  echo "
   Configuring Tomcat server.xml ...
  "

  if [ -v POSTGRESQL_URL ]; then
	  POSTGRESQL_URL="jdbc:postgresql://$POSTGRESQL_SERVICE_HOST:$POSTGRESQL_SERVICE_PORT/$POSTGRESQL_DATABASE"
  fi

  sed -i 's/POSTGRESQL_USER/'"$POSTGRESQL_USER"'/g' $LIFERAY_HOME/server.xml_template
  sed -i 's/POSTGRESQL_PASSWORD/'"$POSTGRESQL_PASSWORD"'/g' $LIFERAY_HOME/server.xml_template
  sed -i 's/POSTGRESQL_URL/'"$POSTGRESQL_URL"'/g' $LIFERAY_HOME/server.xml_template

  cp $LIFERAY_HOME/server.xml_template  $CATALINA_HOME/conf/server.xml

  echo "
  Continuing.
  "
}

run_portal() {

  set -e

  # Drop root privileges if we are running liferay
  # allow the container to be started with `--user`
  if [ "$1" = 'catalina.sh' -a "$(id -u)" = '0' ]; then
    # Change the ownership of Liferay Shared Volume to liferay

    if [[ ! -d "$LIFERAY_SHARED" ]]; then
      mkdir -p $LIFERAY_SHARED
    fi

    chown -R liferay:liferay $LIFERAY_SHARED
    chown -R liferay:liferay $LIFERAY_HOME
    
    set -- gosu liferay "$@"
  fi

  # As argument is not related to liferay,
  # then assume that user wants to run his own process,
  # for example a `bash` shell to explore this image
  exec "$@"
}

main "$@"
