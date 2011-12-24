#!/bin/bash

configs () {
  if [ -n "${CONFIG_FILE}" ]; then
    echo "Using config file ${CONFIG_FILE}"
  else
    echo "No config file, gathering config info"
  fi
}

usage () {
  echo "Usage:  ./install-accumulo.sh [options]"
  echo "  -f config_file (load configs instead of prompting)"
  echo "  -h display this message (other options ignored)"
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
