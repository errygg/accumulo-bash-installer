#!/bin/bash

CMD="./bin/pre_install.sh"

# Test pre_install
test_pre_install_calls_check_os() {
    # setup
    local msg="check_os called"
    source_pre_install
    stub_external_functions
    stub_function "check_os" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_check_config_file() {
    # setup
    local msg="check_config_file called"
    source_pre_install
    stub_external_functions
    stub_function "check_os"
    stub_function "check_config_file" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_set_install_dir() {
    local a=1
}

test_pre_install_calls_set_hdfs_dir() {
    local a=1
}

test_pre_install_calls_set_java_home() {
    local a=1
}

test_pre_install_calls_check_ssh() {
    local a=1
}

source_pre_install() {
    # use --no-run so it only loads and prints configs
    # need to dump to /dev/null, or the output shows in the test
    source "${CMD}" > /dev/null
}

stub_external_functions() {
    stub_function "yellow"
    stub_function "log"
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
