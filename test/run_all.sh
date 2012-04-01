#!/usr/bin/env bash

# just a simple file to aggregate all tests.  Tests should be run from the project root so it can find the directories correctly, i.e ./test/all.sh.  If you want to run a subset or tests, comment them out below

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

run_tests() {
    local file=$1
    echo -n -e "\033[0;32mRunning ${file}\033[0m\n"
    "$(_script_dir)/${file}"
}

#run_tests "test_install.sh"
run_tests "test_pre_install.sh"

