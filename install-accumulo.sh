#!/bin/bash

configs () {
  if [ -n "${CONFIG_FILE}" ]; then
    # Load variables from file
    echo "Using config file ${CONFIG_FILE}"
  else
    # get all variable from user
    echo "No config file, gathering config info"
  fi
  # check os
  # get install directory
  # get java_home
  # check ssh localhost
  # TODO: ask which version of accumulo.  Need a good way to manage
}

usage () {
  echo "Usage:  ./install-accumulo.sh [options]"
  echo "  -f config_file (load configs instead of prompting)"
  echo "  -h display this message (other options ignored)"
  # TODO: add options here.  Make passed in options override -f options
  exit 0;
}


main () {
  echo "The Accumulo Installer Script...."
  # parse args here
  while (( $# > 0 ))
  do
      token="$1"
      shift
      if [ "${token}" == "-f" ]; then
        if [ -f "${1}" ]; then
          CONFIG_FILE=$1
        else
          echo "ERROR: config file '${1}' does not exist"
          usage
        fi
        shift 
      elif [ "${token}" == "-h" ]; then
        usage
      else
        echo "ERROR: unknown option"
        usage
      fi
  done
  # setup configs and prereqs
  configs 
  # install hadoop
  # install zookeeper
  # install accumulo
}

main $*
