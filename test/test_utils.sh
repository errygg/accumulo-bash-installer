#!/bin/bash

FILE="./bin/utils.sh"

# test log
test_log_dumps_to_log_file_if_present() {
    # setup
    LOG_FILE=/tmp/jacklog.log
    touch "${LOG_FILE}"
    source_file
    local msg="Here is a log message"

    # execute
    local output=$(log "${msg}")
    local dump=$(cat ${LOG_FILE})

    # assert
    assert_re_match "${dump}" "${msg}"

    # cleanup
    rm -rf $LOG_FILE
    unset LOG_FILE
}

test_log_if_LOG_FILE_not_set() {
    # setup
    unset LOG_FILE
    source_file
    local msg="Here is another log message"

    # execute
    local output=$(log "${msg}")

    # assert
    assert_re_match "${output}" "${msg}"
}

test_log_skips_log_file_if_missing() {
    # setup
    source_file
    LOG_FILE=/tmp/jacklog2.log
    rm -rf "${LOG_FILE}" > /dev/null
    local msg="Still loggin here"

    # execute
    local output=$(log "${msg}")

    # assert
    assert_re_match "${output}" "${msg}"

    # cleanup
    unset LOG_FILE
}

test_log_echos_message() {
    # setup
    source_file
    local msg="Can you hear me now"

    # execute
    local output=$(log "${msg}")

    # assert
    assert_re_match "${output}" "${msg}"
}

test_log_uses_INDENT() {
    # setup
    source_file
    INDENT="              "
    local msg="Can you hear me now"

    # execute
    local output=$(log "${msg}")

    # assert
    assert_re_match "${output}" "${INDENT}${msg}"

    # cleanup
    unset INDENT
}

# load file so we can execute functions
source_file() {
    # need to dump to /dev/null, or the output shows in the test
    source "${FILE}" > /dev/null
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
