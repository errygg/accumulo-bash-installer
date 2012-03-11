#!/bin/bash

usage () {
  # TODO: add options here.  Make passed in options override -f options
  cat <<-EOF
  Usage:  ./install-accumulo.sh [options]

  Options:

    -h                  display this message
    -f <config_file>    load configs from instead of prompting

EOF
}

abort() {
  echo
  red "Aborting....."
  red "$@" 1>&2
  echo
  exit 1
}

log() {
  echo "$@"
}

# use for errors
red() {
  # TODO: test on linux, works on Mac OSX
  echo -e "\033[1;31m$@\033[0m"
}

# use for extra emphasis that aren't errors
green() {
  echo -e "\033[1;32m$@\033[0m"
}

# use when prompting for input
blue() {
  echo -e "\033[1;34m$@\033[0m"
}

set_config_file () {
  test -f $1 || abort "invalid config file, '$1' does not exist"
  CONFIG_FILE=$1
}

configs () {
  # check os
  PLATFORM=`uname`
  case $PLATFORM in
    "Darwin") log "You are installing to OS: ${PLATFORM}" ;;
    *)
      abort "Installer does not support ${PLATFORM}"
  esac

  # check for a config file
  if [[ -n "${CONFIG_FILE}" ]]; then
    log "Using $CONFIG_FILE.  Here is the contents"
    cat $CONFIG_FILE
  else
    log "No config file found, we will get them from you now"
  fi

  # get install directory
  if [[ -n $INSTALL_DIR ]]; then
    #TODO test this with configs and options
    log "Install directory already set to ${INSTALL_DIR}"
  else
    blue "Enter the install directory"
    read -e INSTALL_DIR
  fi

  # check install direcotry
  if [[ -d $INSTALL_DIR ]]; then
      abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory."
  else
      log "Creating directory ${INSTALL_DIR}"
      mkdir -p $INSTALL_DIR
  fi

  # get java_home
  if [[ ! -n $JAVA_HOME ]]; then
      blue "Enter a location for JAVA_HOME"
      read -e JAVA_HOME
  fi

  # check java_home
  if [[ ! -d $JAVA_HOME ]]; then
      abort "JAVA_HOME does not exist: ${JAVA_HOME}"
  else
      echo "JAVA_HOME set to ${JAVA_HOME}"
  fi

  # check ssh localhost
  local HOSTNAME=$(hostname)
  local SSH_HOST=$(ssh -o 'PreferredAuthentications=publickey' localhost "hostname")
  if [[ "${HOSTNAME}" == "${SSH_HOST}" ]]; then
      log "It appears passwordless ssh is setup correctly."
  else
      abort "Doesn't appear passwordless ssh is setup correctly, expect ${HOSTNAME}, got ${SSH_HOST}"
  fi
  # TODO: ask which version of accumulo.  Need a good way to manage
}



main () {
  green "The Accumulo Installer Script...."
  # setup configs and prereqs
  configs
  # install hadoop
  # install zookeeper
  # install accumulo
}

# parse args here
while test $# -ne 0; do
  arg=$1; shift
  case $arg in
    -h) usage; exit 0 ;;
    -f) set_config_file $1; shift ;;
    *)
      usage
      abort "ERROR - unknown option : ${arg}"
      ;;
  esac
done

main $*
