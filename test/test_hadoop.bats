load test_helper

CMD="$BATS_TEST_DIRNAME/../bin/hadoop.sh"
TMP_DIR="/tmp/ac-hadoop-test"
DEBUG=true # comment this out if you don't want the extra info, only shows debug for failures
any="[[:print:]]" # regex match of any printable character, use $any in the regex string

setup() {
    mkdir "${TMP_DIR}"
    . $CMD > /dev/null
    INSTALL_DIR="${TMP_DIR}"
    HADOOP_VERSION="6.1"
    HADOOP_MIRROR="http://some.url.here"
    ARCHIVE_DIR="${TMP_DIR}/hadoop_archive_dir"
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

stub_install_hadoop_functions() {
    stub_function "unarchive_file"
    stub_function "setup_directory"
    stub_function "setup_hadoop_conf"
    stub_function "setup_core_site"
    stub_function "setup_mapred_site"
    stub_function "setup_hdfs_site"
    stub_function "setup_hadoop_env"
    stub_function "format_namenode"
    stub_function "start_hadoop"
    stub_function "test_install"
}

test_variable_set() {
    # setup
    stub_install_hadoop_functions # just in case
    unset "$1"

    # execute
    run install_hadoop

    # assert
    assert_error
    assert_output_matches "You must set $1"
}

@test "install_hadoop fails if INSTALL_DIR not set" {
    test_variable_set "INSTALL_DIR"
}

@test "install_hadoop fails if HADOOP_VERSION not set" {
    test_variable_set "HADOOP_VERSION"
}

@test "install_hadoop fails if HADOOP_MIRROR not set" {
    test_variable_set "HADOOP_MIRROR"
}

@test "install_hadoop fails if ARCHIVE_DIR not set" {
    test_variable_set "ARCHIVE_DIR"
}

@test "install_hadoop fails if INSTALL_DIR/hadoop* exists" {

}

@test "install_hadoop sets HADOOP_FILENAME" {

}

@test "install_hadoop sets HADOOP_SOURCE" {

}

@test "install_hadoop sets HADOOP_DEST" {

}

test_function_called() {
     fname=$1
     # setup
     local msg="$fname called"
     stub_function "$fname" "${msg}" 0

     # execute
     run install_hadoop

     # assert
     assert_no_error
     assert_output_matches "${msg}"
}

@test "install_hadoop call unarchive_file" {
    stub_install_hadoop_functions && test_function_called "unarchive_file"
}

@test "install_hadoop call setup_directory" {
    stub_install_hadoop_functions && test_function_called "setup_directory"
}

@test "install_hadoop call setup_hadoop_conf" {
    stub_install_hadoop_functions && test_function_called "setup_hadoop_conf"
}

@test "install_hadoop call setup_core_site" {
    stub_install_hadoop_functions && test_function_called "setup_core_site"
}

@test "install_hadoop call setup_mapred_site" {
    stub_install_hadoop_functions && test_function_called "setup_mapred_site"
}

@test "install_hadoop call setup_hdfs_site" {
    stub_install_hadoop_functions && test_function_called "setup_hdfs_site"
}

@test "install_hadoop call setup_hadoop_env" {
    stub_install_hadoop_functions && test_function_called "setup_hadoop_env"
}

@test "install_hadoop call format_namenode" {
    stub_install_hadoop_functions && test_function_called "format_namenode"
}

@test "install_hadoop call start_hadoop" {
    stub_install_hadoop_functions && test_function_called "start_hadoop"
}

@test "install_hadoop call test_install" {
    stub_install_hadoop_functions && test_function_called "test_install"
}


