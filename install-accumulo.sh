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

red() {
  # TODO: test on linux, works on Mac OSX
  echo -e "\033[1;31m$@\033[0m"
}

green() {
  echo -e "\033[1;32m$@\033[0m"
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
  if [[ -n "${CONFIG_FILE}" ]]; then
    log "Using $CONFIG_FILE.  Here is the contents"
    cat $CONFIG_FILE
  else
    log "No config file"
  fi
  # get install directory
  if [[ -n $INSTALL_DIR ]]; then
    #TODO test this with configs and options
    log "Install directory already set to ${INSTALL_DIR}"
  else
    green "Enter the install directory"
    read -e INSTALL_DIR
  fi
  if [[ -d $INSTALL_DIR ]]; then 
    abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory."
  fi
  mkdir -p $INSTALL_DIR
  
  # get java_home
  # check ssh localhost
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
