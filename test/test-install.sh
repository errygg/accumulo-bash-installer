#!/bin/bash

CMD="./bin/install.sh"

# Testing the command line arguments
test_help_option_prints_usage() {
    local output=$("${CMD}" -h)
    assert_re_match "${output}" "Usage: "
}

test_config_file_option_when_file_does_not_exist() {
    local bad_file="somefile"
    local output=$("${CMD}" -f "${bad_file}" --no-run 2>&1)
    assert_re_match "${output}" "invalid config file, '${bad_file}' does not exist"
}

test_config_file_option_when_file_exists() {
    local good_file="/tmp/somefile"
    touch "${good_file}"
    local output=$("${CMD}" -f "${good_file}" --no-run 2>&1)
    assert_re_match "${output}" "CONFIG_FILE: ${good_file}"
    rm "${good_file}"
}

test_install_dir_option_when_directory_exists() {
    local existing_dir="/tmp/install_dir2"
    mkdir "${existing_dir}"
    local output=$("${CMD}" -d "${existing_dir}" --no-run 2>&1)
    assert_re_match "${output}" "Directory '${existing_dir}' already exists."
    rmdir "${existing_dir}"
}

test_install_dir_option_when_directory_does_not_exist() {
    local new_dir="/tmp/new_install_dir"
    local output=$("${CMD}" -d "${new_dir}" --no-run 2>&1)
    assert_re_match "${output}" "INSTALL_DIR: ${new_dir}"
}

# Testing the install function
test_install_calls_setup_configs() {
    # setup
    local msg="setup_configs called"
    load_file
    stub_setup_configs "${msg}"

    # execute
    local output=$(install)

    # assert
    assert_re_match "${output}" "${msg}"
}


# HELPERS
# load file so we can execute functions
load_file() {
    # use --no-run so it only loads and prints configs
    # need to dump to /dev/null, or the output shows in the test
    source "${CMD}" --no-run > /dev/null
}

# overwrite setup_configs, having it dump the msg arg
stub_setup_configs() {
    local msg=$1
    eval "function setup_configs() {
        echo \"${msg}\"
        exit 0;
    }"
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
