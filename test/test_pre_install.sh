#!/bin/bash

CMD="./bin/pre_install.sh"

# Test pre_install
test_pre_install_calls_check_os() {
    # setup
    local msg="check_os called"
    source_pre_install && stub_pre_install_functions
    stub_function "check_os" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_check_config_file() {
    # setup
    local msg="check_config_file called"
    source_pre_install && stub_pre_install_functions
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
    source_pre_install && stub_pre_install_functions
    stub_function "set_install_dir" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_set_hdfs_dir() {
    # setup
    local msg="set_hdfs_dir called"
    source_pre_install && stub_pre_install_functions
    stub_function "set_hdfs_dir" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_set_java_home() {
    # setup
    local msg="set_java_home called"
    source_pre_install && stub_pre_install_functions
    stub_function "set_java_home" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_pre_install_calls_check_ssh() {
    # setup
    local msg="check_ssh called"
    source_pre_install && stub_pre_install_functions
    stub_function "check_ssh" "${msg}" 1

    # execute
    local output=$(pre_install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_check_os_fails_for_cygwin() {
    #setup
    source_pre_install
    local os="cygwin"
    _uname() {
        echo "${os}"
    }

    # execute
    local output=$(check_os)

    # assert
    assert_re_match "${output}" "Installer does not support ${os}"
}

test_check_os_passes_for_darwin() {
    #setup
    source_pre_install
    local os="Darwin"
    _uname() {
        echo "${os}"
    }

    # execute
    local output=$(check_os)

    # assert
    assert_re_match "${output}" "You are installing to OS: ${os}"
}

test_check_config_file_uses_CONFIG_FILE() {
    # setup
    local TEST_VAR="mike is unit testing bash here"
    CONFIG_FILE="/tmp/somefile"
    touch $CONFIG_FILE && echo "CHECK_ME=\"${TEST_VAR}\"" > $CONFIG_FILE

    # execute
    local output=$(check_config_file)

    # assert
    assert_re_match "${output}" "Using $CONFIG_FILE."

    # cleanup
    rm $CONFIG_FILE
}

test_check_config_file_sources_CONFIG_FILE() {
    # setup
    local TEST_VAR="mike is still unit testing bash here"
    CONFIG_FILE="/tmp/somefile"
    touch $CONFIG_FILE && echo "CHECK_ME=\"${TEST_VAR}\"" > $CONFIG_FILE
    # need to overwrite yellow again to grab CHECK_ME
    eval "function yellow() {
      echo $(env | grep CHECK_ME)
    }"

    # execute
    local output=$(check_config_file)

    # assert
    assert_re_match "${output}" "${TEST_VAR}"

    # cleanup
    rm $CONFIG_FILE
}

test_check_config_file_shows_no_config_file_set() {
    a=1
}

source_pre_install() {
    stub_utils
    # need to dump to /dev/null, or the output shows in the test
    source "${CMD}" > /dev/null
}

stub_utils() {
    # must escape $
    eval "function log() {
      echo \"\$@\"
    }"
    eval "function yellow() {
      echo \"yellow - \$@\"
    }"
    eval "function abort() {
      echo \"aborting - \$@\"
    }"
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

# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
