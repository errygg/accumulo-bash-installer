#!/bin/bash

CMD="./bin/install.sh"

# Testing the command line arguments
test_option_help_prints_usage() {
    local output=$("${CMD}" -h)
    assert_re_match "${output}" "Usage: "
}

test_option_config_file_when_file_does_not_exist() {
    local bad_file="somefile"
    local output=$("${CMD}" -f "${bad_file}" --no-run 2>&1)
    assert_re_match "${output}" "invalid config file, '${bad_file}' does not exist"
}

test_option_config_file_when_file_exists() {
    local good_file="/tmp/somefile"
    touch "${good_file}"
    local output=$("${CMD}" -f "${good_file}" --no-run 2>&1)
    assert_re_match "${output}" "CONFIG_FILE: ${good_file}"
    rm "${good_file}"
}

test_option_install_dir_when_directory_exists() {
    local existing_dir="/tmp/install_dir2"
    mkdir "${existing_dir}"
    local output=$("${CMD}" -d "${existing_dir}" --no-run 2>&1)
    assert_re_match "${output}" "Directory '${existing_dir}' already exists."
    rmdir "${existing_dir}"
}

test_option_install_dir_when_directory_does_not_exist() {
    local new_dir="/tmp/new_install_dir"
    local output=$("${CMD}" -d "${new_dir}" --no-run 2>&1)
    assert_re_match "${output}" "INSTALL_DIR: ${new_dir}"
}

# Testing the install function
test_install_calls_pre_install() {
    # setup
    local msg="pre_install called"
    load_file
    stub_function "pre_install" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_install_calls_install_hadoop() {
    # setup
    local msg="hadoop called"
    load_file
    stub_function "pre_install"
    stub_function "install_hadoop" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_install_calls_install_zookeeper() {
    # setup
    local msg="zookeeper called"
    load_file
    stub_function "pre_install"
    stub_function "install_hadoop"
    stub_function "install_zookeeper" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_install_calls_install_accumulo() {
    # setup
    local msg="accumulo called"
    load_file
    stub_function "pre_install"
    stub_function "install_hadoop"
    stub_function "install_zookeeper"
    stub_function "install_accumulo" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_install_calls_post_installo() {
    # setup
    local msg="post install called"
    load_file
    stub_function "pre_install"
    stub_function "install_hadoop"
    stub_function "install_zookeeper"
    stub_function "install_accumulo"
    stub_function "post_install" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}


ARCHIVE_DIR="${HOME}/.accumulo-install-archive" #copied from file, is there a better way

test_script_when_archive_dir_exists() {
    # setup
    if [ ! -d "${ARCHIVE_DIR}" ]; then
        mkdir "${ARCHIVE_DIR}"
        REMOVE=true
    fi

    # execute
    local output=$("${CMD}"  --no-run 2>&1)

    # assert
    assert_no_re_match "${output}" "Creating archive dir ${ARCHIVE_DIR}"

    # cleanup
    if [ "${REMOVE}" == "true" ]; then
        rm -rf "${ARCHIVE_DIR}"
        unset REMOVE
    fi
}

test_script_when_archive_dir_does_not_exist() {
    # setup
    if [ -d "${ARCHIVE_DIR}" ]; then
        mv "${ARCHIVE_DIR}" "${ARCHIVE_DIR}-moved"
        MOVE=true
    fi

    # execute
    local output=$("${CMD}"  --no-run 2>&1)

    # assert
    assert_re_match "${output}"  "Creating archive dir "
    # ran into problems asserting when home directory was on a mapped drive with a $ in the path
    #assert_re_match "${output}"  "Creating archive dir ${ARCHIVE_DIR}"

    # cleanup
    if [ "${MOVE}" == "true" ]; then
        rm -rf "${ARCHIVE_DIR}"
        mv "${ARCHIVE_DIR}-moved" "${ARCHIVE_DIR}"
        unset MOVE
    fi
}

# Not going to test the --no-run option, or the _script_dir function or the variables.
# To fragile and not needed

# load file so we can execute functions
load_file() {
    # use --no-run so it only loads and prints configs
    # need to dump to /dev/null, or the output shows in the test
    source "${CMD}" --no-run > /dev/null
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
