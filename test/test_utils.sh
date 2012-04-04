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

test_log_handles_color() {
    # setup
    source_file
    local color="31"
    local msg="Am I pretty?"

    # execute
    local output=$(log "${msg}" "${color}")

    # assert
    # TODO: figure out how to actually test this
    assert_re_match "${output}" "${msg}"
}

# yellow test
test_yellow_calls_log_with_33() {
    # setup
    source_file
    eval "function log() {
        echo \"\$1 - \$2\"
    }"
    local msg="dont be scared"

    # execute
    local output=$(yellow "${msg}")

    # assert
    assert_re_match "${output}" "${msg} - 33"
}

# red test
test_red_calls_log_with_31() {
    # setup
    source_file
    eval "function log() {
        echo \"\$1 - \$2\"
    }"
    local msg="why you so mad"

    # execute
    local output=$(red "${msg}")

    # assert
    assert_re_match "${output}" "${msg} - 31"
}

# green test
test_green_calls_log_with_32() {
    # setup
    source_file
    eval "function log() {
        echo \"\$1 - \$2\"
    }"
    local msg="I am envious of you bash"

    # execute
    local output=$(green "${msg}")

    # assert
    assert_re_match "${output}" "${msg} - 32"
}

# blue test
test_blue_calls_log_with_34() {
    # setup
    source_file
    eval "function log() {
        echo \"\$1 - \$2\"
    }"
    local msg="are you cold"

    # execute
    local output=$(blue "${msg}")

    # assert
    assert_re_match "${output}" "${msg} - 34"
}


# load file so we can execute functions
source_file() {
    # need to dump to /dev/null, or the output shows in the test
    source "${FILE}" > /dev/null
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
