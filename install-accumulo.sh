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
  echo " $@" 1>&2
  echo 
  exit 1
}


log() {
  echo "  o $@"
}

set_config_file () {
  test -f $1 || abort "invalid config file, '$1' does not exist"
  CONFIG_FILE=$1
}

configs () {
  # check os
  # get install directory
  # get java_home
  # check ssh localhost
  # TODO: ask which version of accumulo.  Need a good way to manage
  if [[ -n "${CONFIG_FILE}" ]]; then
    log "Using $CONFIG_FILE"
  else
    log "No config file"
  fi
}



main () {
  echo "The Accumulo Installer Script...."
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
