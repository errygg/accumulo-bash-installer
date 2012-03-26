#!/bin/bash

test_help_option_prints_usage() {
    local output=$(./install-accumulo.sh -h)
    assert_re_match "${output}" "Usage: "
}

test_config_file_option_when_file_does_not_exist() {
    local bad_file="somefile"
    local output=$(./install-accumulo.sh -f "${bad_file}" --no-run 2>&1)
    assert_re_match "${output}" "invalid config file, '${bad_file}' does not exist"
}

test_config_file_option_when_file_exists() {
    local good_file="/tmp/somefile"
    touch "${good_file}"
    local output=$(./install-accumulo.sh -f "${good_file}" --no-run 2>&1)
    assert_re_match "${output}" "CONFIG_FILE: ${good_file}"
    rm "${good_file}"
}

test_install_dir_option_when_directory_exists() {
    local existing_dir="/tmp/install_dir2"
    mkdir "${existing_dir}"
    local output=$(./install-accumulo.sh -d "${existing_dir}" --no-run 2>&1)
    assert_re_match "${output}" "Directory '${existing_dir}' already exists."
    rmdir "${existing_dir}"
}

test_install_dir_option_when_directory_does_not_exist() {
    local new_dir="/tmp/new_install_dir"
    local output=$(./install-accumulo.sh -d "${new_dir}" --no-run 2>&1)
    assert_re_match "${output}" "INSTALL_DIR: ${new_dir}"
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
. lib/shunit2-2.1.6/src/shunit2
