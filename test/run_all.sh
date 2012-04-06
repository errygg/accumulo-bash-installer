#!/usr/bin/env bash

# just a simple file to aggregate all tests.  Tests should be run from the project root so it can find the directories correctly, i.e ./test/run_all.sh.  You can run one test file by passing in as a arg, otherwise, you will run all test_* files in the test directory.

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

run_tests() {
    local file=$1
    echo -n -e "\033[0;32mRunning ${file}\033[0m\n"
    "$(_script_dir)/${file}"
}


# simple arg, allows you to run one test, ie
# run_all test_install.sh
# with no args, it will run all tests
if [ $# -eq 1 ]; then
    run_tests $1
else
    for t in "$(_script_dir)"/test_*.sh; do
        run_tests $(basename $t)
    done
fi
