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
    eval "function green() {
      echo \"green - \$@\"
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
    stub_function "unarchive_hadoop_file"
    stub_function "configure_hadoop"
    stub_function "start_hadoop"
    stub_function "test_hadoop"
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

@test "install_hadoop calls unarchive_hadoop_file" {
    stub_install_hadoop_functions && test_function_called "unarchive_hadoop_file"
}

@test "install_hadoop calls configure_hadoop" {
    stub_install_hadoop_functions && test_function_called "configure_hadoop"
}

@test "install_hadoop call start_hadoop" {
    stub_install_hadoop_functions && test_function_called "start_hadoop"
}

@test "install_hadoop call test_hadoop" {
    stub_install_hadoop_functions && test_function_called "test_hadoop"
}

# test unarchive_file

@test "unarchive_hadoop_file calls check_archive_file with DEST and SRC" {
    # setup
    HADOOP_SOURCE="some source"
    HADOOP_DEST="some dest"
    stub_function "sys"
    eval "function check_archive_file() {
        echo \"check_archive_file \$1 \$2\"
    }"

    # execute
    run unarchive_hadoop_file

    # assert
    assert_no_error
    assert_output_matches "check_archive_file ${HADOOP_DEST} ${HADOOP_SOURCE}"
}

@test "unarchive_hadoop_file extracts the file into INSTALL_DIR" {
    # setup
    HADOOP_DEST="some other dest"
    stub_function "check_archive_file"
    eval "function sys() {
        echo \"\$1\"
    }"

    # execute
    run unarchive_hadoop_file

    # assert
    assert_no_error
    assert_output_matches "tar -xzf ${HADOOP_DEST} -C ${INSTALL_DIR}"
}

# test configure_hadoop

stub_conf_functions() {
    stub_function "configure_hadoop_home"
    stub_function "configure_hadoop_conf"
    stub_function "configure_core_site"
    stub_function "configure_mapred_site"
    stub_function "configure_hdfs_site"
    stub_function "configure_hadoop_env"
    stub_function "configure_namenode"
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

@test "configure_hadoop calls configure_hadoop_home" {
    stub_conf_functions && test_conf_function_called "configure_hadoop_home"
}

@test "configure_hadoop calls configure_hadoop_conf" {
    stub_conf_functions && test_conf_function_called "configure_hadoop_conf"
}

@test "configure_hadoop calls configure_core_site" {
    stub_conf_functions && test_conf_function_called "configure_core_site"
}

@test "configure_hadoop calls configure_mapred_site" {
    stub_conf_functions && test_conf_function_called "configure_mapred_site"
}

@test "configure_hadoop calls configure_hdfs_site" {
    stub_conf_functions && test_conf_function_called "configure_hdfs_site"
}

@test "configure_hadoop calls configure_hadoop_env" {
    stub_conf_functions && test_conf_function_called "configure_hadoop_env"
}

@test "configure_hadoop calls configure_namenode" {
    stub_conf_functions && test_conf_function_called "configure_namenode"
}


# test start_hadoop

@test "start_hadoop calls start-all" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"
    HADOOP_HOME="${INSTALL_DIR}/bleh-bleh"

    # execute
    run start_hadoop

    # assert
    assert_no_error
    assert_output_matches "${INSTALL_DIR}/bleh-bleh/bin/start-all.sh"
}

# test test_hadoop

@test "test_hadoop creates a hdfs directory" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"
    dir1="ifyoulivedhere"
    HADOOP_HOME="${INSTALL_DIR}/${dir1}"

    # execute
    run test_hadoop

    # assert
    assert_no_error
    assert_output_matches "${INSTALL_DIR}/${dir1}/bin/hadoop fs -mkdir "
}

@test "test_hadoop checks hdfs directory" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"
    dir1="youdbe"
    HADOOP_HOME="${INSTALL_DIR}/${dir1}"

    # execute
    run test_hadoop

    # assert
    assert_no_error
    assert_output_matches "${INSTALL_DIR}/${dir1}/bin/hadoop fs -ls "
}

@test "test_hadoop removes hdfs directory" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"
    dir1="homenow"
    HADOOP_HOME="${INSTALL_DIR}/${dir1}"

    # execute
    run test_hadoop

    # assert
    assert_no_error
    assert_output_matches "${INSTALL_DIR}/${dir1}/bin/hadoop fs -rmr "
}

# test configure_hadoop_home

@test "configure_hadoop_home creates symlink" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"

    # execute
    run configure_hadoop_home

    # assert
    assert_no_error
    assert_output_matches "ln -s ${INSTALL_DIR}/hadoop-${HADOOP_VERSION} ${INSTALL_DIR}/hadoop"
}

@test "configure_hadoop_home sets HADOOP_HOME" {
    # setup
    stub_function "sys"

    # execute
    run configure_hadoop_home

    # assert
    assert_no_error
    assert_output_matches "HADOOP_HOME set to ${INSTALL_DIR}/hadoop"
}

# test configure_hadoop_conf

@test "configure_hadoop_conf fails if HADOOP_HOME not set" {
    # setup
    unset HADOOP_HOME

    # execute
    run configure_hadoop_conf

    # assert
    assert_error
    assert_output_matches "You must set HADOOP_HOME to call configure_hadoop_conf"
}

@test "configure_hadoop_conf sets HADOOP_CONF" {
    # setup
    HADOOP_HOME="${TMP_DIR}/somehadoophome"

    # execute
    run configure_hadoop_conf

    # assert
    assert_no_error
    assert_output_matches "HADOOP_CONF set to ${HADOOP_HOME}/conf"
}

# test configure_core_site

@test "configure_core_site creates a core-site.xml" {
    # setup
    HADOOP_CONF="${INSTALL_DIR}"

    # execute
    configure_core_site 2>&1 > /dev/null
    run cat "${HADOOP_CONF}/core-site.xml"

    # assert
    assert_no_error
    assert_output_matches "hdfs://localhost:9000"
}

# test configure_mapred_site

@test "configure_mapred_site creates a mapred-site.xml" {
    # setup
    HADOOP_CONF="${INSTALL_DIR}"

    # execute
    configure_mapred_site 2>&1 > /dev/null
    run cat "${HADOOP_CONF}/mapred-site.xml"

    # assert
    assert_no_error
    assert_output_matches "localhost:9001"
}

# test configure_hdfs_site

@test "configure_hdfs_site creates a hdfs-site.xml" {
    # setup
    HADOOP_CONF="${INSTALL_DIR}"
    HDFS_DIR="blahblahblahdfs"

    # execute
    configure_hdfs_site 2>&1 > /dev/null
    run cat "${HADOOP_CONF}/hdfs-site.xml"

    # assert
    assert_no_error
    assert_output_matches "${HDFS_DIR}/data"
}

@test "configure_hdfs_site aborts if HDFS_DIR is not set" {
    # setup
    HADOOP_CONF="${INSTALL_DIR}"

    # execute
    run configure_hdfs_site

    # assert
    assert_error
    assert_output_matches "You must have HDFS_DIR set to run setup_hdfs_site"
}

# test configure_hadoop_env

@test "configure_hadoop_env creates a hadoop-env.sh" {
    # setup
    HADOOP_CONF="${INSTALL_DIR}"
    JAVA_HOME="somejavadir"

    # execute
    configure_hadoop_env 2>&1 > /dev/null
    run cat "${HADOOP_CONF}/hadoop-env.sh"

    # assert
    assert_no_error
    assert_output_matches "export JAVA_HOME=${JAVA_HOME}"
}

@test "configure_hadoop_env aborts if JAVA_HOME not set" {
    # setup
    HADOOP_CONF="${INSTALL_DIR}"
    unset JAVA_HOME

    # execute
    run configure_hadoop_env

    # assert
    assert_error
    assert_output_matches "You must have JAVA_HOME set to run setup_hadoop_env"
}

# test configure_namenode

@test "configure_namenode calls format" {
    # setup
    eval "function sys() {
        echo \"\$1\"
    }"
    HADOOP_HOME="${INSTALL_DIR}/blah-blah"

    # execute
    run configure_namenode

    # assert
    assert_no_error
    assert_output_matches "${INSTALL_DIR}/blah-blah/bin/hadoop namenode -format"
}
