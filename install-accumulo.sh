#!/bin/bash



main () {
  echo "The Accumulo Installer Script...."
  # parse args here
  echo "Num Args: $#"
  if [ $# -eq 0 ]; then
    echo "No args passed in"
  else
    echo "Args: $*"
    args=`getopt fh $*`
    set -- $args
    for i
    do
      case "$i"
      in 
        -f)
          echo "-f set"
          echo flag $i set; sflags="${i#-}$sflags";
          shift;;
        -h)
          echo "-h set"
          shift;;
        --)
          shift; break;;
      esac
    done
  fi
  # setup configs and prereqs
  # install hadoop
  # install zookeeper
  # install accumulo
}

main $*
