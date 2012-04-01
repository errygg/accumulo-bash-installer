#!/bin/bash

CMD="./bin/pre_install.sh"

# Test pre_install
test_pre_install_calls_check_os() {
    # setup
    local msg="check_os called"
    source_pre_install
    stub_pre_install_functions && stub_external_functions
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
    stub_pre_install_functions && stub_external_functions
    stub_function "check_config_file" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_set_install_dir() {
    # setup
    local msg="set_install_dir called"
    source_pre_install
    stub_pre_install_functions && stub_external_functions
    stub_function "set_install_dir" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_set_hdfs_dir() {
    # setup
    local msg="set_hdfs_dir called"
    source_pre_install
    stub_pre_install_functions && stub_external_functions
    stub_function "set_hdfs_dir" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_set_java_home() {
    # setup
    local msg="set_java_home called"
    source_pre_install
    stub_pre_install_functions && stub_external_functions
    stub_function "set_java_home" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_check_ssh() {
    # setup
    local msg="check_ssh called"
    source_pre_install
    stub_pre_install_functions && stub_external_functions
    stub_function "check_ssh" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

source_pre_install() {
    # use --no-run so it only loads and prints configs
    # need to dump to /dev/null, or the output shows in the test
    source "${CMD}" > /dev/null
}

stub_pre_install_functions() {
    # just stub all the functions for a clean pass through
    # the method
    stub_function "check_os"
    stub_function "check_config_file"
    stub_function "set_install_dir"
    stub_function "set_hdfs_dir"
    stub_function "set_java_home"
    stub_function "check_ssh"
}

stub_external_functions() {
    stub_function "yellow"
    stub_function "log"
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
