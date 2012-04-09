#!/usr/bin/env bash

# just a simple file to aggregate all tests and make bats a show errors a little easier
# needs more checks and cleanup if I want to submit this back to bats or share it anywhere

shopt -s compat31

# copy of this function from install.sh
_script_dir() {
    if [ -z "${SCRIPT_DIR}" ]; then
    # even resolves symlinks, see
    # http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
        local SOURCE="${BASH_SOURCE[0]}"
        while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
        SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    fi
    echo "${SCRIPT_DIR}"
}

# setup bats
PATH="${PATH}:$(_script_dir)/lib/bats/libexe"

run_test() {
    local file=$1
    local filename=$(basename $1)
    echo -n -e "\n\033[0;36mRunning ${filename}\033[0m\n"
    "$(_script_dir)/lib/bats/bin/bats" "${file}"
    local retVal=$?
    if [ "$retVal" -gt 0 ]; then
       echo -n -e "\033[0;31m${filename} had errors\033[0m\n"
    else
        echo -n -e "\033[0;32m${filename} passed\033[0m\n"
    fi
    return $retVal
}


# simple arg, allows you to run one test, ie
# run_all test_install.bats
# with no args, it will run all tests
retVal=0
if [ $# -eq 1 ]; then
    run_test $1
    retVal=$?
elif [ $# -eq 0 ]; then
    for t in "$(_script_dir)"/test_*.bats; do
        run_test $t
        if [ "$?" -gt 0 ]; then
            retVal=1
        fi
    done
    if [ "$retVal" -gt 0 ]; then
        echo -n -e "\n\033[0;31mThere were errors\033[0m\n"
    else
        echo -n -e "\n\033[0;32mAll passed\033[0m\n"
    fi
else
    echo "You must pass in zero or one argument"
fi

exit $retVal
