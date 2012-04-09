#!/bin/bash

CMD="./bin/pre_install.sh"


# get_hdfs_dir tests

test_get_hdfs_dir_fail_if_INSTALL_DIR_not_set() {
    # setup
    source_pre_install
    unset INSTALL_DIR

    # execute
    local output=$(get_hdfs_dir)

    # assert
    assert_re_match "${output}" "INSTALL_DIR is not set"
}

test_get_hdfs_dir_fails_if_INSTALL_DIR_does_not_exist() {
    # setup
    source_pre_install
    INSTALL_DIR=/tmp/inohere
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null

    # execute
    local output=$(get_hdfs_dir)

    # assert
    assert_re_match "${output}" "Install dir ${INSTALL_DIR} does not exist"
}

test_get_hdfs_dir_sets_HDFS_DIR() {
    # setup
    source_pre_install
    INSTALL_DIR=/tmp/junk9
    get_install_dir > /dev/null
    eval "function light_blue() {
        echo \${HDFS_DIR}
    }"

    # execute
    local output=$(get_hdfs_dir)

    # assert
    assertEquals "${output}" "${INSTALL_DIR}/hdfs"

    # cleanup
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null
    unset INSTALL_DIR
}

test_get_hdfs_dir_makes_HDFS_DIR() {
    # setup
    source_pre_install
    INSTALL_DIR=/tmp/junk5
    get_install_dir > /dev/null

    # execute
    local output=$(get_hdfs_dir)

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

# get_java_home tests

test_get_java_home_with_JAVA_HOME_set_and_dir_exists() {
    # setup
    source_pre_install
    local tmp_dir=/tmp/javahome1
    mkdir -p "${tmp_dir}"
    JAVA_HOME="${tmp_dir}"

    # execute
    local output=$(get_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME set to ${JAVA_HOME}"

    # cleanup
    rm -rf ${tmp_dir}
}

test_get_java_home_with_JAVA_HOME_set_and_dir_does_not_exist() {
    # setup
    source_pre_install
    local tmp_dir=/tmp/javahome1
    JAVA_HOME="${tmp_dir}"

    # execute
    local output=$(get_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME does not exist: ${JAVA_HOME}"

    # cleanup
    rm -rf ${tmp_dir}
}

test_get_java_home_reads_JAVA_HOME_when_dir_exists() {
    # setup
    source_pre_install
    unset JAVA_HOME
    local dir="/tmp/javajunk3"
    eval "function read_input() {
      echo ${dir}
    }"
    mkdir "${dir}"

    # execute
    local output=$(get_java_home)

    # assert
    assert_re_match "${output}" "JAVA_HOME set to ${dir}"

    # cleanup
    rm -rf "${dir}"
}

test_get_java_home_read_JAVA_HOME_when_dir_does_not_exist() {
    # setup
    source_pre_install
    unset JAVA_HOME
    local dir="/tmp/javajunk4"
    eval "function read_input() {
      echo ${dir}
    }"

    # execute
    local output=$(get_java_home)

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
