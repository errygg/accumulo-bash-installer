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
    stub_function "setup_hadoop_home"
    stub_function "configure_hadoop"
#    stub_function "setup_hadoop_conf"
#    stub_function "setup_core_site"
#    stub_function "setup_mapred_site"
#    stub_function "setup_hdfs_site"
#    stub_function "setup_hadoop_env"
#    stub_function "format_namenode"
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

@test "install_hadoop fails if INSTALL_DIR is not writable" {
    # setup
    chmod 555 "$INSTALL_DIR"

    # execute
    run install_hadoop

    # assert
    assert_error
    assert_output_matches "The directory ${INSTALL_DIR} is not writable by you"
}

@test "install_hadoop fails if INSTALL_DIR/hadoop* exists" {
    # setup
    mkdir "${INSTALL_DIR}/hadoop-"

    # execute
    run install_hadoop

    # assert
    assert_error
    assert_output_matches "Looks like hadoop is already installed"
}

@test "install_hadoop sets HADOOP_FILENAME" {
    # setup
    stub_install_hadoop_functions
    eval "function log(){
        echo \"\${HADOOP_FILENAME}\"
    }"

    # execute
    run install_hadoop

    # assert
    assert_no_error
    assert_output_matches "hadoop-${HADOOP_VERSION}.tar.gz"
}

@test "install_hadoop sets HADOOP_SOURCE" {
    # setup
    stub_install_hadoop_functions
    eval "function log(){
        echo \"\${HADOOP_SOURCE}\"
    }"

    # execute
    run install_hadoop

    # assert
    assert_no_error
    assert_output_matches "${HADOOP_MIRROR}/hadoop-${HADOOP_VERSION}.tar.gz"
}

@test "install_hadoop sets HADOOP_DEST" {
    # setup
    stub_install_hadoop_functions
    eval "function log(){
        echo \"\${HADOOP_DEST}\"
    }"

    # execute
    run install_hadoop

    # assert
    assert_no_error
    assert_output_matches "${ARCHIVE_DIR}/hadoop-${HADOOP_VERSION}.tar.gz"
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

@test "install_hadoop calls unarchive_file" {
    stub_install_hadoop_functions && test_function_called "unarchive_file"
}

@test "install_hadoop calls setup_hadoop_home" {
    stub_install_hadoop_functions && test_function_called "setup_hadoop_home"
}

@test "install_hadoop calls configure_hadoop" {
    stub_install_hadoop_functions && test_function_called "configure_hadoop"
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

# test unarchive_file

@test "unarchive_file calls check_archive_file with DEST and SRC" {
    # setup
    HADOOP_SOURCE="some source"
    HADOOP_DEST="some dest"
    stub_function "sys"
    eval "function check_archive_file() {
        echo \"check_archive_file \$1 \$2\"
    }"

    # execute
    run unarchive_file

    # assert
    assert_no_error
    assert_output_matches "check_archive_file ${HADOOP_DEST} ${HADOOP_SOURCE}"
}

@test "unarchive_file extracts the file into INSTALL_DIR" {
    # setup
    HADOOP_DEST="some other dest"
    stub_function "check_archive_file"
    eval "function sys() {
        echo \"\$1\"
    }"

    # execute
    run unarchive_file

    # assert
    assert_no_error
    assert_output_matches "tar -xzf ${HADOOP_DEST} -C ${INSTALL_DIR}"
}

@test "setup_hadoop_home creates symlink" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"

    # execute
    run setup_hadoop_home

    # assert
    assert_no_error
    assert_output_matches "ln -s ${INSTALL_DIR}/hadoop-${HADOOP_VERSION} ${INSTALL_DIR}/hadoop"
}

@test "setup_hadoop_home sets HADOOP_HOME" {
    # setup
    stub_function "sys"

    # execute
    run setup_hadoop_home

    # assert
    assert_no_error
    assert_output_matches "HADOOP_HOME set to ${INSTALL_DIR}/hadoop"
}

# test configure_hadoop

stub_conf_functions() {
    stub_function "setup_core_site"
    stub_function "setup_mapred_site"
    stub_function "setup_hdfs_site"
    stub_function "setup_hadoop_env"
}

@test "configure_hadoop sets HADOOP_CONF" {
    # setup
    stub_conf_functions
    HADOOP_HOME="${INSTALL_DIR}/hadoop"

    # execute
    run configure_hadoop

    # assert
    assert_no_error
    assert_output_matches "HADOOP_CONF set to ${INSTALL_DIR}/hadoop/conf"

}

test_conf_function_called() {
    fname=$1
    # setup
    local msg="$fname called"
    stub_function "$fname" "${msg}" 0

    # execute
    run configure_hadoop

    # assert
    assert_no_error
    assert_output_matches "${msg}"
}

@test "configure_hadoop calls setup_core_site" {
    stub_conf_functions && test_conf_function_called "setup_core_site"
}

@test "configure_hadoop calls setup_mapred_site" {
    stub_conf_functions && test_conf_function_called "setup_mapred_site"
}

@test "configure_hadoop calls setup_core_site" {
    stub_conf_functions && test_conf_function_called "setup_hdfs_site"
}

@test "configure_hadoop calls setup_core_site" {
    stub_conf_functions && test_conf_function_called "setup_hadoop_env"
}

# test format_namenode

@test "format_namenode calls format" {

}

# test start_hadoop

@test "start_hadoop calls start-all" {

}

# test test_hadoop

@test "test_hadoop creates a hdfs directory" {

}

@test "test_hadoop checks hdfs directory" {

}

@test "test_hadoop removes hdfs directory" {

}

# test setup_core_site

@test "setup_core_site creates a core-site.xml" {

}

# test setup_mapred_site

@test "setup_mapred_site creates a mapred-site.xml" {

}

# test setup_hdfs_site

@test "setup_hdfs_site creates a hdfs-site.xml" {

}

# test setup_hadoop_env

@test "setup_hadoop_env creates a hadoop-env.sh" {

}
