load test_helper

CMD="$BATS_TEST_DIRNAME/../bin/pre_install.sh"
TMP_DIR="/tmp/ac-tes-install"
DEBUG=true # comment this out if you don't want the extra info, only shows debug for failures
any="[[:print:]]" # regex match of any printable character, use $any in the regex string

setup() {
    mkdir "${TMP_DIR}"
    . $CMD > /dev/null
    # stub out the utils functions, must escape $
    eval "function log() {
      echo \"\$@\"
    }"
    eval "function yellow() {
      echo \"yellow - \$@\"
    }"
    eval "function light_blue() {
      echo \"light_blue - \$@\"
    }"
    eval "function abort() {
      echo \"aborting - \$@\"
      exit 1
    }"
}

teardown() {
    rm -rf "${TMP_DIR}"
}

stub_pre_install_functions() {
    stub_function "check_os"
    stub_function "check_config_file"
    stub_function "get_install_dir"
    stub_function "get_hdfs_dir"
    stub_function "get_java_home"
    stub_function "check_ssh"
}

test_function_called() {
     fname=$1
     # setup
     local msg="$fname called"
     stub_function "$fname" "${msg}" 0

     # execute
     run pre_install

     # assert
     assert_no_error
     assert_output_matches "${msg}"
}

@test "pre_install calls check_os" {
    stub_pre_install_functions && test_function_called "check_os"
}

@test "pre_install calls check_config_file" {
    stub_pre_install_functions && test_function_called "check_config_file"
}

@test "pre_install calls get_install_dir" {
    stub_pre_install_functions && test_function_called "get_install_dir"
}

@test "pre_install calls get_hdfs_dir" {
    stub_pre_install_functions && test_function_called "get_hdfs_dir"
}

@test "pre_install calls get_java_home" {
    stub_pre_install_functions && test_function_called "get_java_home"
}

@test "pre_install calls check_ssh" {
    stub_pre_install_functions && test_function_called "check_ssh"
}

@test "check_os fails for cygwin" {
    # setup
    os="cygwin"
    stub_function "_uname" "$os"

    # execute
    run check_os

    # assert
    assert_error
    assert_output_matches "Installer does not support ${os}"
}

@test "check_os passes for darwin" {
    # setup
    os="Darwin"
    stub_function "_uname" "$os"

    # execute
    run check_os

    # assert
    assert_no_error
    assert_output_matches "You are installing to OS: ${os}"
}

# check_config_file tests

@test "check_config_file uses CONFIG_FILE" {
    # setup
    TEST_VAR="mike is unit testing bash here"
    CONFIG_FILE="${TMP_DIR}/somefile"
    touch $CONFIG_FILE && echo "CHECK_ME=\"${TEST_VAR}\"" > $CONFIG_FILE

    # execute
    run check_config_file

    # assert
    assert_no_error
    assert_output_matches "Using $CONFIG_FILE."
}

@test "check_config_file sources CONFIG_FILE" {
    # setup
    TEST_VAR="mike is still unit testing bash here"
    CONFIG_FILE="/${TMP_DIR}/somefile2"
    touch $CONFIG_FILE && echo "CHECK_ME=\"${TEST_VAR}\"" > $CONFIG_FILE
    # need to overwrite yellow again to grab CHECK_ME
    eval "function yellow() {
      echo \$(env | grep CHECK_ME)
    }"

    # execute
    run check_config_file

    # assert
    assert_no_error
    assert_output_matches "${TEST_VAR}"
}

@test "check_config_file shows no config_file set" {
    # execute
    run check_config_file

    # assert
    assert_no_error
    assert_output_matches "No config file found, we will get them from you now"
}

# get_install_dir tests

@test "get_install_dir uses INSTALL_DIR" {
    #setup
    dir="${TMP_DIR}/junk1"
    INSTALL_DIR="${dir}"

    # execute
    run get_install_dir

    # assert
    assert_no_error
    assert_output_matches "Install directory already set to ${dir}"
}

@test "get_install_dir prompts if INSTALL_DIR variable empty" {
    #setup
    dir="${TMP_DIR}/junk3"
    eval "function read_input() {
      echo ${dir}
    }"

    # execute
    run get_install_dir

    # assert
    assert_no_error
    assert_output_matches "Creating directory ${dir}"
}

@test "get_install_dir aborts if INSTALL_DIR exists" {
    #setup
    dir="${TMP_DIR}/junk2"
    INSTALL_DIR="${dir}"
    mkdir "${dir}"

    # execute
    run get_install_dir

    # assert
    assert_error
    assert_output_matches "Directory '${dir}' already exists. You must install to a new directory."
}

@test "get_install_dir says it creates INSTALL_DIR" {
    #setup
    dir="${TMP_DIR}/junk8"
    INSTALL_DIR="${dir}"

    # execute
    run get_install_dir

    # assert
    assert_no_error
    assert_output_matches "Creating directory ${dir}"
}

@test "get_install_dir actually creates INSTALL_DIR" {
    #setup
    dir="${TMP_DIR}/junk14"
    INSTALL_DIR="${dir}"

    # execute
    run get_install_dir && ls -d "${INSTALL_DIR}"

    # assert
    assert_no_error
    assert_output_matches "${INSTALL_DIR}"
}

# get_hdfs_dir tests

@test "get_hdfs_dir fails if INSTALL_DIR not set" {
    # execute
    run get_hdfs_dir

    # assert
    assert_error
    assert_output_matches "INSTALL_DIR is not set"
}

@test "get_hdfs_dir fails if INSTALL_DIR does not exist" {
    # setup
    INSTALL_DIR="${TMP_DIR}/inohere"
    rm -rf "${INSTALL_DIR}" 2>&1 > /dev/null

    # execute
    run get_hdfs_dir

    # assert
    assert_error
    assert_output_matches "Install dir ${INSTALL_DIR} does not exist"
}

@test "get_hdfs_dir sets HDFS_DIR" {
    # setup
    INSTALL_DIR="${TMP_DIR}/junk9"
    mkdir "${INSTALL_DIR}"
    eval "function light_blue() {
        echo \${HDFS_DIR}
    }"

    # execute
    run get_hdfs_dir

    # assert
    assert_no_error
    assert_output_equals "${INSTALL_DIR}/hdfs"
}

@test "get_hdfs_dir says it made HDFS_DIR" {
    # setup
    INSTALL_DIR="${TMP_DIR}/junk5"
    mkdir "${INSTALL_DIR}"

    # execute
    run get_hdfs_dir

    # assert
    assert_output_matches "Making HDFS directory ${INSTALL_DIR}/hdfs"
}

@test "get_hdfs_dir actually makes HDFS_DIR" {
    # setup
    INSTALL_DIR="${TMP_DIR}/junk5"
    mkdir "${INSTALL_DIR}"

    # execute
    run get_hdfs_dir

    # assert
    assert_no_error
    assert_directory_exists "${INSTALL_DIR}/hdfs"
}

# get_java_home tests

@test "get_java_home with JAVA_HOME set to existing directory" {
    # setup
    tmp_dir="${TMP_DIR}/javahome1"
    mkdir -p "${tmp_dir}"
    JAVA_HOME="${tmp_dir}"

    # execute
    run get_java_home

    # assert
    assert_no_error
    assert_output_matches "JAVA_HOME set to ${JAVA_HOME}"
}

@test "get_java_home with JAVA_HOME set to nonexistant directory" {
    # setup
    tmp_dir="${TMP_DIR}/javahome2"
    JAVA_HOME="${tmp_dir}"

    # execute
    run get_java_home

    # assert
    assert_error
    assert_output_matches "JAVA_HOME does not exist: ${JAVA_HOME}"
}

@test "get_java_home prompts when JAVA_HOME is missing and the input directory exists" {
    # setup
    unset JAVA_HOME
    local dir="${TMP_DIR}/javajunk3"
    stub_function "read_input" "${dir}"
    mkdir "${dir}"

    # execute
    run get_java_home

    # assert
    assert_no_error
    assert_output_matches "JAVA_HOME set to ${dir}"
}

@test "get_java_home prompts when JAVA_HOME is missing but the input directory does not exist" {
    # setup
    unset JAVA_HOME
    dir="${TMP_DIR}javajunk4"
    stub_function "read_input" "${dir}"

    # execute
    run get_java_home

    # assert
    assert_error
    assert_output_matches "JAVA_HOME does not exist: ${dir}"
}

# check_ssh tests

@test "check_ssh when host is wrong" {
    # setup
    fake_host="Cryme a river boys"
    stub_function "_hostname" "${fake_host}"
    stub_function "_ssh" "stop cyring"

    # execute
    run check_ssh

    # assert
    assert_error
    assert_output_matches "Problem with SSH$any*Expected $fake_host, but got$any*$"
}

@test "check_ssh when ssh fails" {
    # setup
    fake_host="Girls just wanna have fun"
    stub_function "_ssh" "" 255

    # execute
    run check_ssh

    # assert
    assert_error
    assert_output_matches "Problem with SSH,$any* Expected $any*, but got .$any*$"
}

@test "check_ssh when it passes" {
    # setup
    local fake_host="host1"
    stub_function "_hostname" "${fake_host}"
    stub_function "_ssh" "${fake_host}"

    # execute
    run check_ssh

    # assert
    assert_no_error
    assert_output_matches "SSH appears good"
}
