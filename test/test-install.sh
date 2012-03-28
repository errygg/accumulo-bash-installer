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
test_install_calls_setup_configs() {
    # setup
    local msg="setup_configs called"
    load_file
    stub_function "setup_configs" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_install_calls_install_hadoop() {
    # setup
    local msg="hadoop called"
    load_file
    stub_function "setup_configs"
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
    stub_function "setup_configs"
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
    stub_function "setup_configs"
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
    stub_function "setup_configs"
    stub_function "install_hadoop"
    stub_function "install_zookeeper"
    stub_function "install_accumulo"
    stub_function "post_install" "${msg}" 1

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_script_when_archive_dir_exists() {
    fail
}

test_script_when_archive_dir_does_not_exist() {
    fail
}

# Not going to test the --no-run option, or the _script_dir function or the variables.
# To fragile and not needed

# HELPERS
# load file so we can execute functions
load_file() {
    # use --no-run so it only loads and prints configs
    # need to dump to /dev/null, or the output shows in the test
    source "${CMD}" --no-run > /dev/null
}

# overwrite functions name in first arg, having it echo the second arg
# so we can inspect the output.  If the third option is present, then the
# stubbed function will exit
stub_function() {
    local fname=$1
    local msg=$2
    local exitnow=$3
    if [ "x${exitnow}" != "x" ]; then
        eval "function ${fname}() {
            echo \"${msg}\"
            exit 0;
        }"
    else
        eval "function ${fname}() {
             echo \"${msg}\"
        }"
    fi
}

# assert re_pattern match the given text
assert_re_match() {
    local text=$1
    local re_pattern=$2
    if [[ ! "${text}" =~ "${re_pattern}" ]]; then
        echo ""
        echo "Expected '${re_pattern}' to be in the following"
        echo "${text}"
        fail
    fi
}

# load shunit2
. test/lib/shunit2-2.1.6/src/shunit2
