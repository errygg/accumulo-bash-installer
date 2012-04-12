load test_helper

CMD="$BATS_TEST_DIRNAME/../bin/utils.sh"
TMP_DIR="/tmp/ac-utils-test"
DEBUG=true # comment this out if you don't want the extra info, only shows debug for failures
any="[[:print:]]" # regex match of any printable character, use $any in the regex string

setup() {
    mkdir "${TMP_DIR}"
    . $CMD > /dev/null
}

teardown() {
    rm -rf "${TMP_DIR}"
}

# test log

@test "log dumps to log file if present" {
    # setup
    LOG_FILE="${TMP_DIR}/jacklog.log"
    touch "${LOG_FILE}"
    msg="Here is a log message"

    # execute
    run log "${msg}" && cat "${LOG_FILE}"

    # assert
    assert_no_error
    assert_output_equals "${msg}"
}

@test "log when LOG_FILE not set" {
    # setup
    unset LOG_FILE
    msg="Here is another log message"

    # execute
    run log "${msg}"

    # assert
    assert_no_error
    assert_output_matches "${msg}"
}

@test "log skips log file if missing" {
    # setup
    LOG_FILE="${TMP_DIR}/jacklog2.log"
    msg="Still loggin here"

    # execute
    run log "${msg}"

    # assert
    assert_no_error
    assert_output_matches "${msg}"
}

@test "log echos message" {
    # setup
    msg="Can you hear me now"

    # execute
    run log "${msg}"

    # assert
    assert_no_error
    assert_output_equals "${msg}"
}

@test "log uses INDENT" {
    # setup
    INDENT="              "
    msg="Can you hear me now"

    # execute
    run log "${msg}"

    # assert
    assert_no_error
    assert_output_equals "${INDENT}${msg}"
}

# not going to test yellow, red, green or blue

# abort test

@test "abort shows Aborting" {
    # setup
    eval "function red() {
      echo \"In red - \$1\"
    }"

    # execute
    run abort

    # assert
    assert_error
    assert_output_matches "In red - Aborting..."
}

@test "abort shows message" {
    # setup
    msg="why you stoppen me"
    eval "function red() {
      echo \"In red - \$1\"
    }"

    # execute
    run abort "${msg}"

    # assert
    assert_error
    assert_output_matches "In red - ${msg}"
}

@test "abort calls cleanup_from_abort" {
    # setup
    cleanup="Cleanup called"
    eval "function cleanup_from_abort() {
        echo \"${cleanup}\"
    }"

    # execute
    run abort

    # assert
    assert_error
    assert_output_matches "${cleanup}"
}

# read_input test

@test "read_input fails with no prompt" {
    # setup - shouldn't hit this, but just in case
    eval "function read() {
        echo \"PROMPT:\$1\$2\"
    }"

    # execute
    run read_input

    # assert
    assert_error
    assert_output_matches "Script requested user input without a prompt"
}

@test "read_input uses INDENT and yellow for prompt" {
    # not really a fan of testing 2 things at once, but this is too silly to break out
    # setup
    prompt="What is your answer"
    eval "function read() {
        echo \"\$@\"
    }"
    stub_function "log"
    INDENT="          "

    # execute
    run read_input "${prompt}"

    # assert
    assert_no_error
    assert_output_equals "-p ${_yellow}${INDENT}${prompt}:${_normal}  -e"
}

@test "read_input grabs user input" {
    # setup
    retVal="My answer is true"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"
    eval "function log() {
        do_nothing=true
    }"

    # execute
    run read_input "Some prompt"

    # assert
    assert_no_error
    assert_output_equals "${retVal}"
}

@test "read_input calls log with prompt and reply" {
    # setup
    prompt="No log file"
    retVal="nologhere"
    eval "function read() {
        REPLY=\"${retVal}\"
    }"
    eval "function log() {
        echo \"\$1\"
    } "

    # execute
    run read_input "${prompt}"

    # assert
    assert_no_error
    assert_output_matches "User entered \(${prompt}: ${retVal}\)"
}

# check_curl

@test "check_curl uses CURL if set" {
    # setup
    var="/path/to/curl"
    CURL="${var}"
    stub_function "_which_curl" "should not get here" 1

    # execute
    run check_curl

    # assert
    assert_no_error
    assert_equals "${var}" "$CURL"
}

@test "check_curl when CURL empty and curl not installed" {
    # setup
    stub_function "_which_curl" "curl1" 1

    # execute
    run check_curl

    # assert
    assert_error
    assert_output_matches "Could not find curl on your path"
}

@test "check_curl when CURL empty and curl installed" {
    # setup
    unset CURL
    curl_path="/curl/lives/here"
    stub_function "_which_curl" "${curl_path}"
    check_curl

    # execute
    run echo "${CURL}"

    # assert
    assert_no_error
    assert_output_equals "${curl_path}"
}

# check_gpg

@test "check_gpg used GPG if set" {
    # setup
    var="/path/to/gpg"
    GPG="${var}"

    # execute
    run check_gpg

    # assert
    assert_equals "${var}" "${GPG}"
}

@test "check_gpg when GPG empty and gpg not installed" {
    # setup
    stub_function "_which_gpg" "curl1" 1

    # execute
    run check_gpg

    # assert
    assert_error
    assert_output_matches "Could not find gpg on your path"
}

@test "check_gpg when GPG empty and gpg installed" {
    # setup
    gpg_path="/gpg/lives/here"
    stub_function "_which_gpg" "${gpg_path}"
    check_gpg

    # execute
    run echo "${GPG}"

    # assert
    assert_no_error
    assert_output_equals "${gpg_path}"
}


# test cleanup_from_abort
stub_cleanup_from_abort_functions() {
     stub_function "stop_accumulo"
     stub_function "stop_zookeeper"
     stub_function "stop_hadoop"
     stub_function "move_log_file"
}


@test "cleanup_from_abort with NO_RUN" {
    # setup
    stub_cleanup_from_abort_functions
    NO_RUN=1

    # execute
    run cleanup_from_abort

    # assert
    assert_no_error
    assert_output_equals ""
}

test_function_called() {
     fname=$1
     # setup
     stub_cleanup_from_abort_functions
     msg="$fname called"
     stub_function "$fname" "${msg}" 0

     # execute
     run cleanup_from_abort

     # assert
     assert_no_error
     assert_output_matches "${msg}"
}


@test "cleanup_from_abort calls stop_accumulo" {
    test_function_called "stop_accumulo"
}

@test "cleanup_from_abort calls stop_zookeeper" {
    test_function_called "stop_zookeeper"
}

@test "cleanup_from_abort calls stop_hadoop" {
    test_function_called "stop_hadoop"
}

@test "cleanup_from_abort calls move_log_file" {
    test_function_called "move_log_file"
}

# TODO: update these tests for zookeeper and accumulo
# once they are installed and running so I can get the correct
# string to check for

# test check java process

@test "check_java_process when Hadoop running" {
    # setup
    stub_function "_jps"

    # execute
    run check_java_process "NameNode"

    # assert
    assert_output_equals "Hadoop running"
}

@test "check_java_process when Hadoop not running" {
    # setup
    eval "function _jps() {
        return 1
    }"

    # execute
    run check_java_process "NameNode"

    # assert
    assert_output_equals "Hadoop not running"
}

@test "check_java_process when Zookeeper running" {
    # setup
    stub_function "_jps"

    # execute
    run check_java_process "zookeeper"

    # assert
    assert_output_equals "Zookeeper running"
}

@test "check_java_process when Zookeeper not running" {
    # setup
    eval "function _jps() {
        return 1
    }"

    # execute
    run check_java_process "zookeeper"

    # assert
    assert_output_equals "Zookeeper not running"
}

@test "check_java_process when Accumulo running" {
    # setup
    stub_function "_jps"

    # execute
    run check_java_process "accumulo"

    # assert
    assert_output_equals "Accumulo running"
}

@test "check_java_process when Accumulo not running" {
    # setup
    eval "function _jps() {
        return 1
    }"

    # execute
    run check_java_process "accumulo"

    # assert
    assert_output_equals "Accumulo not running"
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

# test check_archive_file

test_check_archive_file_when_no_FILE_SRC() {
    # setup
    source_file

    # execute
    local output=$(check_archive_file "dest" 2>&1)

    # assert
    assert_re_match "${output}" "You must pass in both FILE_DEST and FILE_SRC"
}

test_check_archive_file_when_no_FILE_DEST_or_FILE_SRC() {
    # setup
    source_file

    # execute
    local output=$(check_archive_file 2>&1)

    # assert
    assert_re_match "${output}" "You must pass in both FILE_DEST and FILE_SRC"
}


test_check_archive_file_when_file_exists() {
    # setup
    source_file
    FILE_DEST=/tmp/blah
    touch ${FILE_DEST}

    # execute
    local output=$(check_archive_file ${FILE_DEST} "blah")

    # assert
    assert_re_match "${output}" "Using existing file ${FILE_DEST}"

    # cleanup
    rm ${FILE_DEST}
    unset FILE_DEST
}

test_check_archive_file_downloads_file_and_sig_when_file_missing() {
    # setup
    source_file
    FILE_SRC="http://blah.com/blah.file"
    FILE_DEST=/tmp/blah
    rm -rf ${FILE_DEST} 2>&1 > /dev/null
    eval "function download_apache_file() {
        echo \"Downloading \$2 to \$1\"
    }"
    eval "function verify_apache_file() {
        echo Calling verify
    }"

    # execute
    local output=$(check_archive_file ${FILE_DEST} ${FILE_SRC})

    # assert
    assert_re_match "${output}" "Downloading ${FILE_SRC} to ${FILE_DEST}"
    assert_re_match "${output}" "Downloading ${FILE_SRC}.asc to ${FILE_DEST}.asc"

    # cleanup
    unset FILE_DEST
    unset FILE_SRC
}

test_check_archive_file_verifies_file_when_file_missing() {
    # setup
    source_file
    FILE_SRC="http://blah.com/blah.file"
    FILE_DEST=/tmp/blah
    rm -rf ${FILE_DEST} 2>&1 > /dev/null
    eval "function download_apache_file() {
        echo Downloading
    }"
    eval "function verify_apache_file() {
        echo Verifying \$1 with \$2
    }"

    # execute
    local output=$(check_archive_file ${FILE_DEST} ${FILE_SRC})

    # assert
    assert_re_match "${output}" "Verifying ${FILE_DEST} with ${FILE_DEST}.asc"

    # cleanup
    unset FILE_DEST
    unset FILE_SRC
}

# test download_apache_file
# test_download_apache_file_with_1_arg
# test_download_apache_file_with_0_arg
# test_download_apache_file_when_check_curl_fails
# test_download_apache_file_when_file_exists
# test_download_apache_file_when_download_fails
# test_download_apache_file_when_download_succeeds

