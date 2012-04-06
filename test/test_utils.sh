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
    eval "function log() {
        do_nothing=true
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
    eval "function log() {
        do_nothing=true
    }"

    # execute
    local output=$(read_input "${prompt}")

    # assert
    assertEquals "${retVal}" "${output}"
}

test_read_input_call_log_with_prompt_and_reply() {
    # setup
    source_file
    unset LOG_FILE
    local prompt="No log file"
    local retVal="nologhere"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"
    local logged=""
    eval "function log() {
        logged=\"\$1\"
    } "

    # execute
    read_input "${prompt}" > /dev/null

    # assert
    assertEquals "User entered (${prompt}: ${retVal})" "${logged}"
}

# check_curl

test_check_curl_when_CURL_set() {
    # setup
    source_file
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
    source_file
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
    source_file
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
    source_file
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
    source_file
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
    source_file
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

test_cleanup_from_abort_with_NO_RUN() {
    # setup
    source_file && stub_cleanup_from_abort_functions
    NO_RUN=1

    # execute
    local output=$(cleanup_from_abort)

    # assert
    assertEquals "" "${output}"

    # cleanup
    unset NO_RUN

}

test_cleanup_from_abort_calls_stop_accumulo() {
    # setup
    source_file && stub_cleanup_from_abort_functions
    local msg="Accumulo stopped ...."
    stub_function "stop_accumulo" "${msg}"

    # execute
    local output=$(cleanup_from_abort)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_cleanup_from_abort_calls_stop_zookeeper() {
    # setup
    source_file && stub_cleanup_from_abort_functions
    local msg="Zookeeper stopped ...."
    stub_function "stop_zookeeper" "${msg}"

    # execute
    local output=$(cleanup_from_abort)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_cleanup_from_abort_calls_stop_hadoop() {
    # setup
    source_file && stub_cleanup_from_abort_functions
    local msg="hadoop stopped ...."
    stub_function "stop_hadoop" "${msg}"

    # execute
    local output=$(cleanup_from_abort)

    # assert
    assert_re_match "${output}" "${msg}"
}

test_cleanup_from_abort_calls_move_log_file() {
    # setup
    source_file && stub_cleanup_from_abort_functions
    local msg="Logs moved yo"
    stub_function "move_log_file" "${msg}"

    # execute
    local output=$(cleanup_from_abort)

    # assert
    assert_re_match "${output}" "${msg}"
}

# TODO: test this for zookeeper and accumulo
# test check java process

test_check_java_process_for_Hadoop_running() {
    # setup
    source_file
    eval "function _jps() {
        return 0
    }"

    # execute
    local output=$(check_java_process "NameNode")

    # assert
    assertEquals "Hadoop running" "${output}"
}

test_check_java_process_for_Hadoop_not_running() {
    # setup
    source_file
    eval "function _jps() {
        return 1
    }"

    # execute
    local output=$(check_java_process "NameNode")

    # assert
    assertEquals "Hadoop not running" "${output}"
}

test_check_java_process_for_Zookeeper_running() {
    # setup
    source_file
    eval "function _jps() {
        return 0
    }"

    # execute
    local output=$(check_java_process "zookeeper")

    # assert
    assertEquals "Zookeeper running" "${output}"

}

test_check_java_process_for_Zookeeper_not_running() {
    # setup
    source_file
    eval "function _jps() {
        return 1
    }"

    # execute
    local output=$(check_java_process "zookeeper")

    # assert
    assertEquals "Zookeeper not running" "${output}"
}

test_check_java_process_for_Accumulo_running() {
    # setup
    source_file
    eval "function _jps() {
        return 0
    }"

    # execute
    local output=$(check_java_process "accumulo")

    # assert
    assertEquals "Accumulo running" "${output}"
}

test_check_java_process_for_Accumulo_not_running() {
    # setup
    source_file
    eval "function _jps() {
        return 1
    }"

    # execute
    local output=$(check_java_process "accumulo")

    # assert
    assertEquals "${output}" "Accumulo not running"
}

test_check_java_process_for_Unknown_abort() {
    # setup
    source_file
    eval "function abort() {
        echo \"Abort called\"
    }"

    # execute
    local output=$(check_java_process "whatthis")

    # assert
    assert_re_match "${output}" "Abort called"

}


# test stop_accumulo

test_stop_accumulo_when_accumulo_not_running() {
    # setup
    source_file
    eval "function check_java_process() {
      echo \"Accumulo not running\"
    }"

    # execute
    local output=$(stop_accumulo)

    # assert
    assert_re_match "${output}" "Accumulo not running, nothing to stop"
}


test_stop_accumulo_when_accumulo_running_but_ACCUMULO_HOME_wrong() {
    # setup
    source_file
    ACCUMULO_HOME="/tmp/fakeaccumulo"
    rm -rf "${ACCUMULO_HOME}" > /dev/null
    eval "function check_java_process() {
      echo \"Accumulo running\"
    }"

    # execute
    local output=$(stop_accumulo)

    # assert
    assert_re_match "${output}" "Directory ${ACCUMULO_HOME} not found, can't shut it down"

    # cleanup
    unset ACCUMULO_HOME
}

test_stop_accumulo_when_accumulo_running_and_ACCUMULO_HOME() {
    # setup
    source_file
    ACCUMULO_HOME="/tmp/fakeaccumulo2"
    mkdir "${ACCUMULO_HOME}"
    eval "function check_java_process() {
      echo \"Accumulo running\"
    }"
    eval "function sys() {
      echo \"Running command: \$1\"
    }"

    # execute
    local output=$(stop_accumulo)

    # assert
    assert_re_match "${output}" "Running command: ${ACCUMULO_HOME}/bin/stop-all.sh"

    # cleanup
    rm -rf "${ACCUMULO_HOME}" > /dev/null
    unset ACCUMULO_HOME
}

# test stop zookeeper

test_stop_zookeeper_when_zookeeper_not_running() {
    # setup
    source_file
    eval "function check_java_process() {
      echo \"Zookeeper not running\"
    }"

    # execute
    local output=$(stop_zookeeper)

    # assert
    assert_re_match "${output}" "Zookeeper not running, nothing to stop"
}


test_stop_zookeeper_when_zookeeper_running_but_ZOOKEEPER_HOME_wrong() {
    # setup
    source_file
    ZOOKEEPEER_HOME="/tmp/fakezookeeper"
    rm -rf "${ZOOKEEPER_HOME}" > /dev/null
    eval "function check_java_process() {
      echo \"Zookeeper running\"
    }"

    # execute
    local output=$(stop_zookeeper)

    # assert
    assert_re_match "${output}" "Directory ${ZOOKEEPER_HOME} not found, can't shut it down"

    # cleanup
    unset ZOOKEEPER_HOME
}

test_stop_zookeeper_when_zookeeper_running_and_ZOOKEEPER_HOME() {
    # setup
    source_file
    ZOOKEEPER_HOME="/tmp/fakezoo2"
    mkdir "${ZOOKEEPER_HOME}"
    eval "function check_java_process() {
      echo \"Zookeeper running\"
    }"
    eval "function sys() {
      echo \"Running command: \$1\"
    }"

    # execute
    local output=$(stop_zookeeper)

    # assert
    assert_re_match "${output}" "Running command: ${ZOOKEEPER_HOME}/bin/zkStop.sh"

    # cleanup
    rm -rf "${ZOOKEEPER_HOME}" > /dev/null
    unset ZOOKEEPER_HOME
}


# test stop hadoop

test_stop_hadoop_when_hadoop_not_running() {
    # setup
    source_file
    eval "function check_java_process() {
      echo \"Hadoop not running\"
    }"

    # execute
    local output=$(stop_hadoop)

    # assert
    assert_re_match "${output}" "Hadoop not running, nothing to stop"
}


test_stop_hadoop_when_hadoop_running_but_HADOOP_HOME_wrong() {
    # setup
    source_file
    HADOOP_HOME="/tmp/fakehadoop"
    rm -rf "${HADOOP_HOME}" > /dev/null
    eval "function check_java_process() {
      echo \"Hadoop running\"
    }"

    # execute
    local output=$(stop_hadoop)

    # assert
    assert_re_match "${output}" "Directory ${HADOOP_HOME} not found, can't shut it down"

    # cleanup
    unset HADOOP_HOME
}

test_stop_hadoop_when_hadoop_running_and_HADOOP_HOME() {
    # setup
    source_file
    HADOOP_HOME="/tmp/fakehadoop2"
    mkdir "${HADOOP_HOME}"
    eval "function check_java_process() {
      echo \"Hadoop running\"
    }"
    eval "function sys() {
      echo \"Running command: \$1\"
    }"

    # execute
    local output=$(stop_hadoop)

    # assert
    assert_re_match "${output}" "Running command: ${HADOOP_HOME}/bin/stop-all.sh"

    # cleanup
    rm -rf "${HADOOP_HOME}" > /dev/null
    unset HADOOP_HOME
}

# test move log file

test_move_log_file_when_INSTALL_DIR_and_LOG_FILE() {
    # setup
    source_file
    INSTALL_DIR=/tmp/install1
    mkdir "${INSTALL_DIR}"
    LOG_FILE=/tmp/logfile1
    touch "${LOG_FILE}"
    local contents="asdfasd4fewefwef"
    echo "${contents}" > "${LOG_FILE}"
    local NEW_LOG_FILE="${INSTALL_DIR}/$(basename $LOG_FILE)"

    # execute
    local output=$(move_log_file)
    local moved_contents=$(cat "${NEW_LOG_FILE}")

    # assert
    assert_re_match "${output}" "Review the log file in ${INSTALL_DIR}"
    assert_re_match "${output}" "less -R ${NEW_LOG_FILE}"
    assert_re_match "${moved_contents}" "${contents}"

    # cleanup
    if [ -e "$LOG_FILE" ]; then
        rm "${LOG_FILE}"
    fi
    rm -rf "${INSTALL_DIR}" > /dev/null
    unset LOG_FILE
    unset INSTALL_DIR
    unset NEW_LOG_FILE
}

test_move_log_file_when_no_INSTALL_DIR_and_LOG_FILE() {
    # setup
    source_file
    INSTALL_DIR=/tmp/install1
    rm -rf  "${INSTALL_DIR}" > /dev/null
    LOG_FILE=/tmp/logfile1
    touch "${LOG_FILE}"

    # execute
    local output=$(move_log_file)

    # assert
    assert_re_match "${output}" "Review the log file in ${LOG_FILE}"
    assert_re_match "${output}" "less -R ${LOG_FILE}"

    # cleanup
    if [ -e "$LOG_FILE" ]; then
        rm "${LOG_FILE}"
    fi
    unset LOG_FILE
    unset INSTALL_DIR
}

# test sys

test_sys_when_no_LOG_FILE() {
    # setup
    source_file
    local cmd="uname"
    local result=$(${cmd})
    unset LOG_FILE
    local bad_stuff="You should not be here"
    eval "function _tee() {
        echo \"${bad_stuff}\"
    }"

    # execute
    local output=$(sys "${cmd}")

    # assert
    assert_re_match "${output}" "Running system command '${cmd}'"
    assert_re_match "${output}" "${result}"
    assert_no_re_match "${output}" "${bad_stuff}"
}

test_sys_with_LOG_FILE() {
    # setup
    source_file
    local cmd="hostname"
    local result=$(${cmd})
    LOG_FILE=/tmp/logfile3
    touch "${LOG_FILE}"

    # execute
    local output=$(sys "${cmd}")

    # assert
    assert_re_match "${output}" "Running system command '${cmd}'"
    assert_re_match "${output}" "${result}"
    assert_re_match "$(cat $LOG_FILE)" "${result}"

    # cleanup
    rm -rf "${LOG_FILE}"
    unset LOG_FILE
}

# load file so we can execute functions
source_file() {
    # need to dump to /dev/null, or the output shows in the test
    source "${FILE}" > /dev/null
}

stub_cleanup_from_abort_functions() {
    stub_function "stop_accumulo"
    stub_function "stop_zookeeper"
    stub_function "stop_hadoop"
    stub_function "move_log_file"
}


# load helper and then shunit2
. test/helper.sh && . test/lib/shunit2-2.1.6/src/shunit2
