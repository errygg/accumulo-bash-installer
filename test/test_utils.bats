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
    assert_no_error
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
    assert_no_error
    assert_output_equals "Hadoop not running"
}

@test "check_java_process when Zookeeper running" {
    # setup
    stub_function "_jps"

    # execute
    run check_java_process "zookeeper"

    # assert
    assert_no_error
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
    assert_no_error
    assert_output_equals "Zookeeper not running"
}

@test "check_java_process when Accumulo running" {
    # setup
    stub_function "_jps"

    # execute
    run check_java_process "accumulo"

    # assert
    assert_no_error
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
    assert_no_error
    assert_output_equals "Accumulo not running"
}

@test "check_java_process for Unknown aborts" {
    # setup
    abort_msg="Abort called"
    stub_function "abort" "${abort_msg}" 1

    # execute
    run check_java_process "whatthis"

    # assert
    assert_error
    assert_output_equals "${abort_msg}"

}

# test stop_accumulo

@test "stop_accumulo when accumulo not running" {
    # setup
    stub_function "check_java_process" "Accumulo not running"

    # execute
    run stop_accumulo

    # assert
    assert_no_error
    assert_output_matches "Accumulo not running, nothing to stop"
}


@test "stop_accumulo when accumulo running but ACCUMULO_HOME wrong" {
    # setup
    ACCUMULO_HOME="/tmp/fakeaccumulo" && rm -rf "${ACCUMULO_HOME}" > /dev/null
    stub_function "check_java_process" "Accumulo running"

    # execute
    run stop_accumulo

    # assert
    assert_no_error
    assert_output_matches "Directory ${ACCUMULO_HOME} not found, can't shut it down"
}

@test "stop_accumulo when accumulo running and ACCUMULO_HOME exists" {
    # setup
    ACCUMULO_HOME="${TMP_DIR}/fakeaccumulo2" && mkdir "${ACCUMULO_HOME}"
    stub_function "check_java_process" "Accumulo running"
    eval "function sys() {
      echo \"Running command: \$1\"
    }"

    # execute
    run stop_accumulo

    # assert
    assert_no_error
    assert_output_matches "Running command: ${ACCUMULO_HOME}/bin/stop-all.sh"
}

# test stop zookeeper

@test "stop_zookeeper when zookeeper not running" {
    # setup
    stub_function "check_java_process" "Zookeeper not running"

    # execute
    run stop_zookeeper

    # assert
    assert_no_error
    assert_output_matches "Zookeeper not running, nothing to stop"
}


@test "stop_zookeeper when zookeeper running but ZOOKEEPER_HOME wrong" {
    # setup
    ZOOKEEPER_HOME="/tmp/fakezookeeper" && rm -rf "${ZOOKEEPER_HOME}" > /dev/null
    stub_function "check_java_process" "Zookeeper running"

    # execute
    run stop_zookeeper

    # assert
    assert_no_error
    assert_output_matches "Directory ${ZOOKEEPER_HOME} not found, can't shut it down"
}

@test "stop_zookeeper when zookeeper running and ZOOKEEPER_HOME exists" {
    # setup
    ZOOKEEPER_HOME="${TMP_DIR}/fakezookeeper" && mkdir "${ZOOKEEPER_HOME}"
    stub_function "check_java_process" "Zookeeper running"
    eval "function sys() {
      echo \"Running command: \$1\"
    }"

    # execute
    run stop_zookeeper

    # assert
    assert_no_error
    assert_output_matches "Running command: ${ZOOKEEPER_HOME}/bin/zkStop.sh"
}


# test stop hadoop

@test "stop_hadoop when hadoop not running" {
    # setup
    stub_function "check_java_process" "Hadoop not running"

    # execute
    run stop_hadoop

    # assert
    assert_output_matches "Hadoop not running, nothing to stop"
}


@test "stop_hadoop when hadoop running but HADOOP_HOME wrong" {
    # setup
    HADOOP_HOME="/tmp/fakehadoop" && rm -rf "${HADOOP_HOME}" > /dev/null
    stub_function "check_java_process" "Hadoop running"

    # execute
    run stop_hadoop

    # assert
    assert_no_error
    assert_output_matches "Directory ${HADOOP_HOME} not found, can't shut it down"
}

@test "stop_hadoop when hadoop running and HADOOP_HOME exists" {
    # setup
    HADOOP_HOME="${TMP_DIR}/fakehadoop2" && mkdir "${HADOOP_HOME}"
    stub_function "check_java_process" "Hadoop running"
    eval "function sys() {
      echo \"Running command: \$1\"
    }"

    # execute
    run stop_hadoop

    # assert
    assert_no_error
    assert_output_matches "Running command: ${HADOOP_HOME}/bin/stop-all.sh"
}

# test move log file

@test "move_log_file message when INSTALL_DIR and LOG_FILE exist" {
    # setup
    INSTALL_DIR="${TMP_DIR}/install1" && mkdir "${INSTALL_DIR}"
    LOG_FILE="${TMP_DIR}/logfile1" && touch "${LOG_FILE}"
    MOVED_LOG_FILE="${INSTALL_DIR}/$(basename $LOG_FILE)"

    # execute
    run move_log_file

    # assert
    assert_no_error
    assert_output_matches "Review the log file in ${INSTALL_DIR}"
    assert_output_matches "less -R ${MOVED_LOG_FILE}"
}

@test "move_log_file actually moves file when INSTALL_DIR and LOG_FILE exist" {
    # setup
    contents="asdfasd4fewefwef"
    INSTALL_DIR="${TMP_DIR}/install2" && mkdir "${INSTALL_DIR}"
    LOG_FILE="${TMP_DIR}/logfile2" && echo "${contents}" > "${LOG_FILE}"
    MOVED_LOG_FILE="${INSTALL_DIR}/$(basename $LOG_FILE)"
    move_log_file > /dev/null

    # execute
    run cat "${MOVED_LOG_FILE}"

    # assert
    assert_no_error
    assert_output_matches "${contents}"
}

@test "move_log_file when LOG_FILE variable set but INSTALL_DIR does not exist" {
    # setup
    INSTALL_DIR="${TMP_DIR}/install1" &&  rm -rf  "${INSTALL_DIR}"
    LOG_FILE="${TMP_DIR}logfile1" && touch "${LOG_FILE}"

    # execute
    run move_log_file

    # assert
    assert_no_error
    assert_output_matches "Review the log file in ${LOG_FILE}"
    assert_output_matches "less -R ${LOG_FILE}"
}

@test "move_log_file when LOG_FILE does not exist" {
    # setup

    # execute
    run move_log_file

    # assert
    assert_no_error
    assert_output_equals ""
}

# test sys

@test "sys doesn't dump to log if LOG_FILE variable doesn't exist" {
    # setup
    cmd="uname"
    bad_msg="You should not see me"
    stub_function "_tee" "${bad_msg}" 1

    # execute
    run sys "${cmd}"

    # assert
    assert_no_error
    assert_output_matches  "$(${cmd})"
    assert_output_does_not_match "${bad_msg}"
}

@test "sys doesn't dump to log if LOG_FILE variable exists but file does not" {
    # setup
    LOG_FILE="${TMP_DIR}/notcreated" && rm -rf "${LOG_FILE}"
    cmd="whoami"
    stub_function "log" "log function" # light_blue and log create the file
    bad_msg="You still should not see me"
    stub_function "_tee" "${bad_msg}" 1

    # execute
    run sys "${cmd}"

    # assert
    assert_no_error
    assert_output_matches  "$(${cmd})"
    assert_output_does_not_match "${bad_msg}"
}

@test "sys with LOG_FILE displays correctly" {
    # setup
    LOG_FILE="${TMP_DIR}/logfile3" && touch "${LOG_FILE}"
    cmd="hostname"

    # execute
    run sys "${cmd}"

    # assert
    assert_no_error
    assert_output_matches "Running system command '${cmd}'"
    assert_output_matches "$(${cmd})"
}

@test "sys with LOG_FILE dumps to log" {
    # setup
    LOG_FILE="${TMP_DIR}/logfile4" && touch "${LOG_FILE}"
    cmd="pwd"
    sys "${cmd}"

    # execute
    run cat "$LOG_FILE"

    # assert
    assert_no_error
    assert_output_matches "$(${cmd})"
}

@test "sys aborts if command fails and LOG_FILE doesn't exist" {
    # setup
    cmd="ls /Ishouldfailforyou"

    # execute
    run sys "${cmd}"

    # assert
    assert_error
    assert_output_matches "Error running ${cmd}"
}

@test "sys exits if command fails and LOG_FILE exists" {
    # setup
    LOG_FILE="${TMP_DIR}/logfile5" && touch "${LOG_FILE}"
    cmd="ls /adirectorythatdoesntexist"

    # execute
    run sys "${cmd}"

    # assert
    assert_error
}

@test "sys exits and dumps to LOG_FILE if it exists" {
    # setup
    LOG_FILE="${TMP_DIR}/logfile6" && touch "${LOG_FILE}"
    cmd="ls /anotherdirectorythatdoesntexist"
    run sys "${cmd}"

    # execute
    run cat "$LOG_FILE"

    # assert
    assert_output_matches "Error running ${cmd}"
}

@test "sys doesn't exit on failure if continue" {
    # setup
    cmd="ls /failmenow"

    # execute
    run sys "${cmd}" "true"

    # assert
    assert_no_error
    assert_output_matches "Error running ${cmd}"
}

# test check_archive_file

@test "check_archive_file with one arg fails" {
    # setup

    # execute
    run check_archive_file "dest"

    # assert
    assert_output_matches "You must pass in both FILE_DEST and FILE_SRC"
}

@test "check_archive_file with no args" {
    # setup

    # execute
    run check_archive_file

    # assert
    assert_output_matches "You must pass in both FILE_DEST and FILE_SRC"
}


@test "check_archive_file when destination file exists" {
    # setup
    FILE_DEST=/tmp/blah && touch ${FILE_DEST}

    # execute
    run check_archive_file ${FILE_DEST} "blah"

    # assert
    assert_output_matches "Using existing file ${FILE_DEST}"
}

@test "check_archive_file downloads file and sig when file missing in dest" {
    # setup
    FILE_SRC="http://blah.com/blah.file"
    FILE_DEST="${TMP_DIR}/blah" && rm -rf ${FILE_DEST}
    eval "function download_apache_file() {
        echo \"Downloading \$2 to \$1\"
    }"
    stub_function "verify_apache_file" "Calling verify"

    # execute
    run check_archive_file ${FILE_DEST} ${FILE_SRC}

    # assert
    assert_output_matches "Downloading ${FILE_SRC} to ${FILE_DEST}"
    assert_output_matches "Downloading ${FILE_SRC}.asc to ${FILE_DEST}.asc"
}

@test_check_archive_file_verifies_file_when_file_missing() {
    # setup
    FILE_SRC="http://blah2.com/blah2.file"
    FILE_DEST="${TMP_DIR}/blah2" && rm -rf ${FILE_DEST}
    stub_function "download_apache_file" "Downloading file"
    eval "function verify_apache_file() {
        echo Verifying \$1 with \$2
    }"

    # execute
    run check_archive_file ${FILE_DEST} ${FILE_SRC}

    # assert
    assert_output_matches "Verifying ${FILE_DEST} with ${FILE_DEST}.asc"
}

@test "check_archive_file when download of file fails" {
    # setup
    FILE_SRC="http://blah3.com/blah3.file"
    FILE_DEST="${TMP_DIR}/blah3" && rm -rf ${FILE_DEST}
    err_msg="Oops sumpin failed"
    stub_function "download_apache_file" "${err_msg}" 1
    stub_function "verify_apache_file" "verify file called"

    # execute
    run check_archive_file ${FILE_DEST} ${FILE_SRC}

    # assert
    assert_error
    assert_output_equals "${err_msg}"
}

@test "check_archive_file when download of sig fails" {
    # setup
    FILE_SRC="http://blah4.com/blah4.file"
    FILE_DEST="${TMP_DIR}/blah4" && rm -rf ${FILE_DEST}
    file_good="file downloaded fine"
    err_msg="sig failed"
    verify_msg="verify file called"
    stub_function "verify_apache_file" "${verify_msg}"
    eval "function download_apache_file() {
        if [ \"\$2\" == \"$FILE_SRC\" ]; then
          echo \"$file_good\"
        elif [ \"\$2\" == \"${FILE_SRC}.asc\" ]; then
          echo \"$err_msg\" && exit 1
        else
          echo Something else called
        fi
    }"

    # execute
    run check_archive_file ${FILE_DEST} ${FILE_SRC}

    # assert
    assert_error
    assert_output_matches "${err_msg}"
    assert_output_does_not_match "${verify_msg}"
}

@test "check_archive_file when verify fails" {
    # setup
    FILE_SRC="http://blah5.com/blah5.file"
    FILE_DEST="${TMP_DIR}/blah5" && rm -rf ${FILE_DEST}
    download_msg="Download called"
    err_msg="Verify failed dude"
    stub_function "download_apache_file" "${download_msg}"
    stub_function "verify_apache_file" "${err_msg}" 1

    # execute
    run check_archive_file ${FILE_DEST} ${FILE_SRC}

    # assert
    assert_error
    # recall assert_output_matches converts \n to ;
    assert_output_matches "^${download_msg}; *${download_msg}; *${err_msg};$"
}

# test download_apache_file

@test "download_apache_file fails with 1 arg aborts" {
    # setup
    stub_function "_curl" "Just making sure this doesn't run" 1
    DST="blah"
    msg="abort called, what you wanna do?"
    stub_function "abort" "${msg}" 1

    # execute
    run download_apache_file $DST

    # assert
    assert_error
    assert_output_equals "${msg}"
}

@test "download_apache_file fails with 0 args" {
    # setup
    stub_function "_curl" "Just making sure this doesn't run" 1
    msg="abort called again, here we go"
    stub_function "abort" "${msg}" 1

    # execute
    run download_apache_file

    # assert
    assert_error
    assert_output_equals "${msg}"
}

@test "download_apache_file when curl check fails" {
    # setup
    stub_function "_curl" "Just making sure this doesn't run" 1
    msg="check curl failed, abort called again, here we go"
    stub_function "check_curl" "${msg}" 1

    # execute
    run download_apache_file "DST" "SRC"

    # assert
    assert_error
    assert_output_equals "${msg}"
}

@test "download_apache_file when destination already exists" {
    # setup
    stub_function "_curl" "Just making sure this doesn't run" 1
    DEST="${TMP_DIR}/downloaded.file" && touch "${DEST}"
    SRC="some url here"
    stub_function "check_curl"

    # execute
    run download_apache_file "$DEST" "${SRC}"

    # assert
    assert_error
    assert_output_matches "${DEST} already exists, not downloading"
}

@test "download_apache_file when download fails" {
    DEST="${TMP_DIR}/dest.file"
    SRC="awesome url"
    stub_function "check_curl"
    msg="This should really the result of failure in the sys method"
    eval "function _curl() {
        echo \"${msg}\"
        return 1
    }"

    # execute
    run download_apache_file "$DEST" "${SRC}"

    # assert
    assert_error
    assert_output_matches "${msg}"
}

@test "download_apache_file when download succeeds" {
    DEST="${TMP_DIR}/put_me_here"
    SRC="this should pass"
    stub_function "check_curl"
    msg="File downloaded, yeah"
    # double echo since this function is executed
    eval "function _curl() {
        echo \"echo $msg\"
    }"

    # execute
    run download_apache_file "$DEST" "${SRC}"

    # assert
    assert_no_error
    assert_output_matches "${msg}"
}

# test verify_apache_file

@test "verify_apache_file fails with 1 arg" {
    # execute
    stub_function "_gpg" "Just making sure this doesn't run" 1
    run verify_apache_file "arg1"

    # assert
    assert_error
    assert_output_matches "You must pass in both file and signature locations"
}

@test "verify_apache_file fails with 0 arg" {
    # execute
    stub_function "_gpg" "Just making sure this doesn't run" 1
    run verify_apache_file

    # assert
    assert_error
    assert_output_matches "You must pass in both file and signature locations"
}

@test "verify_apache_file is skipped with SKIP_VERIFY variable" {
    # setup
    stub_function "_gpg" "Just making sure this doesn't run" 1
    SKIP_VERIFY=true

    # execute
    run verify_apache_file "file" "src"

    # assert
    assert_no_error
    assert_output_matches "Verification skipped by user option"
}

@test "verify_apache_file aborts if FILE does not exist" {
    # setup
    stub_function "_gpg" "Just making sure this doesn't run" 1
    FILE="${TMP_DIR}/file" && rm -rf "${FILE}"

    # execute
    run verify_apache_file "${FILE}" "sig"

    # assert
    assert_error
    assert_output_matches "${FILE} not found, verification failed"
}

@test "verify_apache_file aborts if SIG does not exist" {
    # setup
    stub_function "_gpg" "Just making sure this doesn't run" 1
    FILE="${TMP_DIR}/file" && touch "${FILE}"
    SIG="${TMP_DIR}/sig" && rm -rf "${SIG}"

    # execute
    run verify_apache_file "${FILE}" "${SIG}"

    # assert
    assert_error
    assert_output_matches "${SIG} not found, verification failed"
}

@test "verify_apache_file aborts if gpg check fails" {
    # setup
    FILE="${TMP_DIR}/file2" && touch "${FILE}"
    SIG="${TMP_DIR}/sig2" && touch "${SIG}"
    err_msg="check_gpg failed, abort called here"
    stub_function "check_gpg" "${err_msg}" 1

    # execute
    run verify_apache_file "${FILE}" "${SIG}"

    # assert
    assert_error
    assert_output_equals "${err_msg}"
}

@test "verify_apache_file continues if gpg fails and user says yes" {
    # setup
    FILE="${TMP_DIR}/file2" && touch "${FILE}"
    SIG="${TMP_DIR}/sig2" && touch "${SIG}"
    stub_function "check_gpg"
    eval "function _gpg() {
        return 1
    }"
    eval "function read_input() {
        echo y
    }"

    # execute
    run verify_apache_file "${FILE}" "${SIG}"

    # assert
    assert_no_error
    assert_output_matches "Verification failed"
    assert_output_matches "Ok, installing unverified file"
}

@test "verify_apache_file aborts if gpg fails and user says no" {
    # setup
    FILE="${TMP_DIR}/file3" && touch "${FILE}"
    SIG="${TMP_DIR}/sig3" && touch "${SIG}"
    stub_function "check_gpg"
    eval "function _gpg() {
        return 1
    }"
    eval "function read_input() {
        echo n
    }"

    # execute
    run verify_apache_file "${FILE}" "${SIG}"

    # assert
    assert_error
    assert_output_matches "Verification failed"
    assert_output_matches "Review output above for more info"
}

@test "verify_apache_file if gpg succeeds" {
    FILE="${TMP_DIR}/file3" && touch "${FILE}"
    SIG="${TMP_DIR}/sig3" && touch "${SIG}"
    stub_function "check_gpg"
    stub_function "_gpg"

    # execute
    run verify_apache_file "${FILE}" "${SIG}"

    # assert
    assert_no_error
    assert_output_matches "Verification passed"
}
