# the Accumulo Bash installer

    **********NOTE****************
    This is not finished.  Try this at your own risk.  I warned you.
    ******************************

# Travis-CI status
[![Build Status](https://secure.travis-ci.org/mjwall/accumulo-bash-installer.png)](http://travis-ci.org/mjwall/accumulo-bash-installer)

# Description
This install script is designed to help you get setup for local Accumulo development.  It is not intended for production installations.  The script will install the following into one directory, configure them for you and start them up:

Hadoop 0.20.2
Zookeeper 3-something
Accumulo 1.3.5


# Usage
To run this script, clone the repo and run the following from the root directory.

    ./bin/install.sh

The -h option will give you more information about the possible options.

If you want to install Accumulo without forking this repo, simply run the following:

    bash <(curl -s https://raw.github.com/mjwall/accumulo-bash-installer/master/dist/install-accumulo.sh)

If you want to see the options, add a -h to the end of the above command as well, and you will get usage.

Once there is a stable release, I'll make a branch and change the cloneless install directions to point to that.  Currently, I have to remember to run 'make dist' to update that script, so it may not be the latest on master.

# Prerequisites

This script requires bash 3.1 or greater, curl and gpg.  It will not run on a Windows system.
