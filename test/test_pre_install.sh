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

# check_os tests

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

# check_config_file tests

test_check_config_file_uses_CONFIG_FILE() {
    # setup
    source_pre_install
    local TEST_VAR="mike is unit testing bash here"
    CONFIG_FILE="/tmp/somefile"
    touch $CONFIG_FILE && echo "CHECK_ME=\"${TEST_VAR}\"" > $CONFIG_FILE

    # execute
    local output=$(check_config_file)

    # assert
    assert_re_match "${output}" "Using $CONFIG_FILE."

    # cleanup
    rm $CONFIG_FILE
    unset CONFIG_FILE
}

test_check_config_file_sources_CONFIG_FILE() {
    # setup
    source_pre_install
    local TEST_VAR="mike is still unit testing bash here"
    CONFIG_FILE="/tmp/somefile"
    touch $CONFIG_FILE && echo "CHECK_ME=\"${TEST_VAR}\"" > $CONFIG_FILE
    # need to overwrite yellow again to grab CHECK_ME
    eval "function yellow() {
      echo \$(env | grep CHECK_ME)
    }"

    # execute
    local output=$(check_config_file)

    # assert
    assert_re_match "${output}" "${TEST_VAR}"

    # cleanup
    rm $CONFIG_FILE
    unset CONFIG_FILE
}

test_check_config_file_shows_no_config_file_set() {
    # setup
    source_pre_install

    # execute
    local output=$(check_config_file)

    # assert
    assert_re_match "${output}" "No config file found, we will get them from you now"
}

# set_install_dir tests

test_set_install_dir_uses_INSTALL_DIR() {
    #setup
    source_pre_install
    local dir=/tmp/junk1
    INSTALL_DIR="${dir}"

    # execute
    local output=$(set_install_dir)

    # assert
    assert_re_match "${output}" "Install directory already set to ${dir}"

    # cleanup
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

test_set_install_dir_prompts_if_INSTALL_DIR_empty() {
    #setup
    source_pre_install
    local dir="/tmp/junk3"
    eval "function read_input() {
      echo ${dir}
    }"

    # execute
    local output=$(set_install_dir)

    # assert
    assert_re_match "${output}" "Creating directory ${dir}"

    # cleanup
    rm -rf "${dir}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

test_set_install_dir_aborts_if_INSTALL_DIR_exists() {
    #setup
    source_pre_install
    local dir=/tmp/junk2
    INSTALL_DIR="${dir}"
    mkdir "${dir}"

    # execute
    local output=$(set_install_dir)

    # assert
    assert_re_match "${output}" "Directory '${dir}' already exists. You must install to a new directory."

    # cleanup
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

test_set_install_dir_makes_INSTALL_DIR() {
    #setup
    source_pre_install
    local dir=/tmp/junk8
    INSTALL_DIR="${dir}"

    # execute
    local output=$(set_install_dir)

    # assert
    assert_re_match "${output}" "Creating directory ${dir}"
    assert_re_match "$(ls -d /tmp/*)" "${INSTALL_DIR}"

    # cleanup
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

# set_hdfs_dir tests

test_set_hdfs_dir_fail_if_INSTALL_DIR_not_set() {
    # setup
    source_pre_install
    unset INSTALL_DIR

    # execute
    local output=$(set_hdfs_dir)

    # assert
    assert_re_match "${output}" "INSTALL_DIR is not set"
}

test_set_hdfs_dir_fails_if_INSTALL_DIR_does_not_exist() {
    # setup
    source_pre_install
    INSTALL_DIR=/tmp/inohere
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null

    # execute
    local output=$(set_hdfs_dir)

    # assert
    assert_re_match "${output}" "Install dir ${INSTALL_DIR} does not exist"
}

test_set_hdfs_dir_sets_HDFS_DIR() {
    # setup
    source_pre_install
    INSTALL_DIR=/tmp/junk9
    set_install_dir > /dev/null
    eval "function yellow() {
        echo \${HDFS_DIR}
    }"

    # execute
    local output=$(set_hdfs_dir)

    # assert
    assertEquals "${output}" "${INSTALL_DIR}/hdfs"

    # cleanup
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

test_set_hdfs_dir_makes_HDFS_DIR() {
    # setup
    source_pre_install
    INSTALL_DIR=/tmp/junk5
    set_install_dir > /dev/null

    # execute
    local output=$(set_hdfs_dir)

    # assert
    assert_re_match "${output}" "Making HDFS directory ${INSTALL_DIR}/hdfs"
    if [ ! -d "${INSTALL_DIR}/hdfs" ]; then
        echo "HDFS directory not created"
        fail
    fi

    # cleanup
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

# set_java_home tests

test_set_java_home_with_JAVA_HOME_set_and_dir_exists() {
    # setup
    source_pre_install
    local tmp_dir=/tmp/javahome1
    mkdir -p "${tmp_dir}"
    JAVA_HOME="${tmp_dir}"

    # execute
    local output=$(set_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME set to ${JAVA_HOME}"

    # cleanup
    rm -rf ${tmp_dir}
}

test_set_java_home_with_JAVA_HOME_set_and_dir_does_not_exist() {
    # setup
    source_pre_install
    local tmp_dir=/tmp/javahome1
    JAVA_HOME="${tmp_dir}"

    # execute
    local output=$(set_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME does not exist: ${JAVA_HOME}"

    # cleanup
    rm -rf ${tmp_dir}
}

test_set_java_home_reads_JAVA_HOME_when_dir_exists() {
    # setup
    source_pre_install
    unset JAVA_HOME
    local dir="/tmp/javajunk3"
    eval "function read_input() {
      echo ${dir}
    }"
    mkdir "${dir}"

    # execute
    local output=$(set_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME set to ${dir}"

    # cleanup
    rm -rf "${dir}"
}

test_set_java_home_read_JAVA_HOME_when_dir_does_not_exist() {
    # setup
    source_pre_install
    unset JAVA_HOME
    local dir="/tmp/javajunk4"
    eval "function read_input() {
      echo ${dir}
    }"

    # execute
    local output=$(set_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME does not exist: ${dir}"
}

# check_ssh tests

test_check_ssh_when_it_fails() {
    # setup
    source_pre_install
    local fake_host="Cryme a river boys"
    eval "function _hostname() {
        echo ${fake_host}
    }"

    # execute
    local output=$(check_ssh)

    # assert
    assert_re_match "${output}" "Problem with SSH, expected $fake_host, but got"
}

test_check_ssh_when_it_passes() {
    # setup
    source_pre_install
    local fake_host="host1"
    eval "function _hostname() {
        echo ${fake_host}
    }"
    eval "function _ssh() {
        echo ${fake_host}
    }"

    # execute
    local output=$(check_ssh)

    # assert
    assert_re_match "${output}" "SSH appears good"
}


# helpers

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
      exit 0
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
