#!/usr/bin/env bash

# just a simple file to aggregate all tests

SCRIPT_DIR=$(dirname $0)

run_tests() {
    local file=$1
    echo -n -e "\033[0;32mRunning ${file}\033[0m\n"
    ./"${SCRIPT_DIR}"/"${file}"
}

run_tests "test_install.sh"
run_tests "test_pre_install.sh"

