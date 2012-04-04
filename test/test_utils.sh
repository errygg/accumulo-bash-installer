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

# not going to test yellow, red, green or blue

# abort test

test_abort_shows_Aborting() {
    # setup
    source_file
    eval "function red() {
      echo \"In red - \$1\"
    }"

    # execute
    local output=$(abort 2>&1) #abort spits to stderr, so redirect here to capture

    # assert
    assert_re_match "${output}" "In red - Aborting..."
}

test_abort_shows_message() {
    # setup
    source_file
    local msg="why you stoppen me"
    eval "function red() {
      echo \"In red - \$1\"
    }"

    # execute
    local output=$(abort "${msg}" 2>&1) #abort spits to stderr, so redirect here to capture

    # assert
    assert_re_match "${output}" "In red - ${msg}"
}

test_abort_calls_cleanup_from_abort() {
    # setup
    source_file
    local cleanup="Cleanup called"
    eval "function cleanup_from_abort() {
        echo \"${cleanup}\"
    }"

    # execute
    local output=$(abort 2>&1)

    # assert
    assert_re_match "${output}" "${cleanup}"
}

test_abort_exits_with_1() {
    # setup
    source_file

    # execute
    (eval "abort") > /dev/null 2>&1
    local exit_status=$?

    # assert
    assertEquals "Expect abort to exit with a 1" 1 $exit_status
}

# read_input test

test_read_input_fails_with_no_prompt() {
    # setup
    source_file

    # execute
    local output=$(read_input 2>&1)

    # assert
    assert_re_match "${output}" "Script requested user input without a prompt"
}

test_read_input_uses_INDENT_and_yellow_for_prompt() {
    # not really a fan of testing 2 things at once, but this is too silly to break out
    # setup
    source_file
    local prompt="What is your answer"
    eval "function read() {
        echo \"PROMPT:\$1\$2\"
    }"
    INDENT="          "

    # execute
    local output=$(read_input "${prompt}")

    # assert
    assert_re_match "${output}" "PROMPT:-p${_yellow}${INDENT}${prompt}:${normal}"
}

test_read_input_grabs_user_input() {
    # setup
    source_file
    local prompt="What is your answer"
    local retVal="Mike"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"

    # execute
    local output=$(read_input "${prompt}")

    # assert
    assertEquals "${retVal}" "${output}"
}

test_read_input_with_no_LOG_FILE() {
    # setup
    source_file
    unset LOG_FILE
    local prompt="No log file"
    local retVal="nologhere"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"

    # execute
    local output=$(read_input "${prompt}")

    # assert
    assertEquals "${retVal}" "${output}"
}

test_read_input_with_LOG_FILE_that_does_not_exist() {
    # setup
    source_file
    LOG_FILE="/tmp/tmp_log_file"
    rm -rf "${LOG_FILE}" > /dev/null
    local prompt="Still o log file"
    local retVal="stillnologhere"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"

    # execute
    local output=$(read_input "${prompt}")

    # assert
    assertEquals "${retVal}" "${output}"
}

test_read_input_with_LOG_FILE() {
    # setup
    source_file
    LOG_FILE="/tmp/tmp_log_file"
    touch "${LOG_FILE}"
    local prompt="No log file"
    local retVal="nologhere"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"

    # execute
    local output=$(read_input "${prompt}")
    local logged=$(cat ${LOG_FILE})

    # assert
    assert_re_match "${logged}" "${prompt}: ${retVal}"

    # cleanup
    rm -rf "${LOG_FILE}" > /dev/null
}

# check_curl

test_check_curl_when_CURL_set() {
    # setup
    local var="/path/to/curl"
    CURL="${var}"

    # execute
    check_curl

    # assert
    assertEquals "${var}" "${CURL}"

    # cleanup
    unset CURL
}

test_check_curl_when_no_CURL_and_no_executable() {
    # setup
    unset CURL
    local check_abort="abort called"
    eval "function _which_curl() {
       return 1
    }"
    eval "function abort() {
       echo \"${check_abort}\"
    }"

    # execute
    local output=$(check_curl)

    # assert
    assert_re_match "${output}" "${check_abort}"

    # cleanup
    unset CURL
}

test_check_curl_when_no_CURL_and_executable() {
    # setup
    unset CURL
    local curl_path="/curl/lives/here"
    eval "function _which_curl() {
       echo \"${curl_path}\"
    }"

    # execute
    check_curl

    # assert
    assertEquals "${curl_path}" "${CURL}"

    # cleanup
    unset CURL
}

# check_gpg

test_check_gpg_when_GPG_set() {
    # setup
    local var="/path/to/gpg"
    GPG="${var}"

    # execute
    check_gpg

    # assert
    assertEquals "${var}" "${GPG}"

    # cleanup
    unset GPG
}

test_check_gpg_when_no_GPG_and_no_executable() {
    # setup
    unset GPG
    local check_abort="abort called"
    eval "function _which_gpg() {
       return 1
    }"
    eval "function abort() {
       echo \"${check_abort}\"
    }"

    # execute
    local output=$(check_gpg)

    # assert
    assert_re_match "${output}" "${check_abort}"

    # cleanup
    unset GPG
}

test_check_gpg_when_no_GPG_and_executable() {
    # setup
    unset GPG
    local gpg_path="/gpg/lives/here"
    eval "function _which_gpg() {
       echo \"${gpg_path}\"
    }"

    # execute
    check_gpg

    # assert
    assertEquals "${gpg_path}" "${GPG}"

    # cleanup
    unset GPG
}


# test cleanup_from_abort
# should stop accumulo if running
# should stop zookeeper if running
# should stop hadoop if running
# should remove install dir
# should give note again about log file


# load file so we can execute functions
source_file() {
    # need to dump to /dev/null, or the output shows in the test
    source "${FILE}" > /dev/null
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
