#!/bin/bash

# https://github.com/mdelapenya/docker-liferay-portal/edit/master/entrypoint.sh

set -o errexit

main() {
  show_motd
  prepare_liferay_portal_properties
  prepare_liferay_tomcat_config
  prepare_liferay_osgi_configs_directory
  run_portal "$@"
}

show_motd() {
  echo "Starting Liferay 7.1 instance.

  LIFERAY_HOME: $LIFERAY_HOME
  "
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
  if [[ ! -f "$LIFERAY_CONFIG_DIR/setenv.sh" ]]; then
    echo "No 'configs/setenv.sh' file found.
  If you wish to provide custom tomcat JVM settings, make sure
  you include a 'configs/setenv.sh' file in the 
  root of your project.

  Continuing.
  "
    return 0
  fi

  echo "Tomcat configuration (setenv.sh) file found.
  "

  cp -r $LIFERAY_CONFIG_DIR/setenv.sh $CATALINA_HOME/bin/setenv.sh

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
