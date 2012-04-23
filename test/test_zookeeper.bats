load test_helper

CMD="$BATS_TEST_DIRNAME/../bin/zookeeper.sh"
TMP_DIR="/tmp/ac-zookeeper-test"
DEBUG=true # comment this out if you don't want the extra info, only shows debug for failures
any="[[:print:]]" # regex match of any printable character, use $any in the regex string

setup() {
    mkdir "${TMP_DIR}"
    . $CMD > /dev/null
    INSTALL_DIR="${TMP_DIR}"
    ZOOKEEPER_VERSION="6.1"
    ZOOKEEPER_MIRROR="http://some.url.here"
    ARCHIVE_DIR="${TMP_DIR}/zookeeper_archive_dir"
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

stub_install_zookeeper_functions() {
    stub_function "unarchive_zookeeper_file"
    stub_function "setup_zookeeper_home"
    stub_function "configure_zookeeper"
    stub_function "start_zookeeper"
    stub_function "test_zookeeper"
}

test_variable_set() {
    # setup
    stub_install_zookeeper_functions # just in case
    unset "$1"

    # execute
    run install_zookeeper

    # assert
    assert_error
    assert_output_matches "You must set $1"
}

@test "install_zookeeper fails if INSTALL_DIR not set" {
    test_variable_set "INSTALL_DIR"
}

@test "install_zookeeper fails if ZOOKEEPER_VERSION not set" {
    test_variable_set "ZOOKEEPER_VERSION"
}

@test "install_zookeeper fails if ZOOKEEPER_MIRROR not set" {
    test_variable_set "ZOOKEEPER_MIRROR"
}

@test "install_zookeeper fails if ARCHIVE_DIR not set" {
    test_variable_set "ARCHIVE_DIR"
}

@test "install_zookeeper fails if INSTALL_DIR is not writable" {
    # setup
    chmod 555 "$INSTALL_DIR"

    # execute
    run install_zookeeper

    # assert
    assert_error
    assert_output_matches "The directory ${INSTALL_DIR} is not writable by you"
}

@test "install_zookeeper fails if INSTALL_DIR/zookeeper* exists" {
    # setup
    mkdir "${INSTALL_DIR}/zookeeper-"

    # execute
    run install_zookeeper

    # assert
    assert_error
    assert_output_matches "Looks like zookeeper is already installed"
}

@test "install_zookeeper sets ZOOKEEPER_FILENAME" {
    # setup
    stub_install_zookeeper_functions
    eval "function log(){
        echo \"\${ZOOKEEPER_FILENAME}\"
    }"

    # execute
    run install_zookeeper

    # assert
    assert_no_error
    assert_output_matches "zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
}

@test "install_zookeeper sets ZOOKEEPER_SOURCE" {
    # setup
    stub_install_zookeeper_functions
    eval "function log(){
        echo \"\${ZOOKEEPER_SOURCE}\"
    }"

    # execute
    run install_zookeeper

    # assert
    assert_no_error
    assert_output_matches "${ZOOKEEPER_MIRROR}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
}

@test "install_zookeeper sets ZOOKEEPER_DEST" {
    # setup
    stub_install_zookeeper_functions
    eval "function log(){
        echo \"\${ZOOKEEPER_DEST}\"
    }"

    # execute
    run install_zookeeper

    # assert
    assert_no_error
    assert_output_matches "${ARCHIVE_DIR}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
}

test_function_called() {
    fname=$1
    # setup
    local msg="$fname called"
    stub_function "$fname" "${msg}" 0

    # execute
    run install_zookeeper

    # assert
    assert_no_error
    assert_output_matches "${msg}"
}

@test "install_zookeeper calls unarchive_zookeeper_file" {
    stub_install_zookeeper_functions && test_function_called "unarchive_zookeeper_file"
}

@test "install_zookeeper calls configure_zookeeper" {
    stub_install_zookeeper_functions && test_function_called "configure_zookeeper"
}

@test "install_zookeeper call start_zookeeper" {
    stub_install_zookeeper_functions && test_function_called "start_zookeeper"
}

@test "install_zookeeper call test_zookeeper" {
    stub_install_zookeeper_functions && test_function_called "test_zookeeper"
}

# test unarchive_zookeeper_file

@test "unarchive_file calls check_archive_file with DEST and SRC" {
    # setup
    ZOOKEEPER_SOURCE="some source"
    ZOOKEEPER_DEST="some dest"
    stub_function "sys"
    eval "function check_archive_file() {
        echo \"check_archive_file \$1 \$2\"
    }"

    # execute
    run unarchive_zookeeper_file

    # assert
    assert_no_error
    assert_output_matches "check_archive_file ${ZOOKEEPER_DEST} ${ZOOKEEPER_SOURCE}"
}

@test "unarchive_file extracts the file into INSTALL_DIR" {
    # setup
    ZOOKEEPER_DEST="some other dest"
    stub_function "check_archive_file"
    eval "function sys() {
        echo \"\$1\"
    }"

    # execute
    run unarchive_zookeeper_file

    # assert
    assert_no_error
    assert_output_matches "tar -xzf ${ZOOKEEPER_DEST} -C ${INSTALL_DIR}"
}

# test configure_zookeeper

stub_conf_functions() {
    stub_function "configure_zookeeper_data_dir"
    stub_function "configure_zookeeper_home"
    stub_function "configure_zoo_cfg"
}

@test "configure_zookeeper sets ZOOKEEPER_CONF" {
    # setup
    stub_conf_functions
    ZOOKEEPER_HOME="${INSTALL_DIR}/zookeeper"

    # execute
    run configure_zookeeper

    # assert
    assert_no_error
    assert_output_matches "ZOOKEEPER_CONF set to ${INSTALL_DIR}/zookeeper/conf"

}

test_conf_function_called() {
    fname=$1
    # setup
    local msg="$fname called"
    stub_function "$fname" "${msg}" 0

    # execute
    run configure_zookeeper

    # assert
    assert_no_error
    assert_output_matches "${msg}"
}

@test "configure_zookeeper calls configure_zookeeper_data_dir" {
    stub_conf_functions && test_conf_function_called "configure_zookeeper_data_dir"
}

@test "configure_zookeeper calls configure_zookeeper_home" {
    stub_conf_functions && test_conf_function_called "configure_zookeeper_home"
}

@test "configure_zookeeper calls configure_zoo_cfg" {
    stub_conf_functions && test_conf_function_called "configure_zoo_cfg"
}

# test start_zookeeper

# @test "start_zookeeper calls start-all" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"
#     ZOOKEEPER_HOME="${INSTALL_DIR}/bleh-bleh"

#     # execute
#     run start_zookeeper

#     # assert
#     assert_no_error
#     assert_output_matches "${INSTALL_DIR}/bleh-bleh/bin/start-all.sh"
# }

# # test test_zookeeper

# @test "test_zookeeper creates a hdfs directory" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"
#     dir1="ifyoulivedhere"
#     ZOOKEEPER_HOME="${INSTALL_DIR}/${dir1}"

#     # execute
#     run test_zookeeper

#     # assert
#     assert_no_error
#     assert_output_matches "${INSTALL_DIR}/${dir1}/bin/zookeeper fs -mkdir "
# }

# @test "test_zookeeper checks hdfs directory" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"
#     dir1="youdbe"
#     ZOOKEEPER_HOME="${INSTALL_DIR}/${dir1}"

#     # execute
#     run test_zookeeper

#     # assert
#     assert_no_error
#     assert_output_matches "${INSTALL_DIR}/${dir1}/bin/zookeeper fs -ls "
# }

# @test "test_zookeeper removes hdfs directory" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"
#     dir1="homenow"
#     ZOOKEEPER_HOME="${INSTALL_DIR}/${dir1}"

#     # execute
#     run test_zookeeper

#     # assert
#     assert_no_error
#     assert_output_matches "${INSTALL_DIR}/${dir1}/bin/zookeeper fs -rmr "
# }

# # test configure_zookeeper_home

# @test "configure_zookeeper_home creates symlink" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"

#     # execute
#     run configure_zookeeper_home

#     # assert
#     assert_no_error
#     assert_output_matches "ln -s ${INSTALL_DIR}/zookeeper-${ZOOKEEPER_VERSION} ${INSTALL_DIR}/zookeeper"
# }

# @test "configure_zookeeper_home sets ZOOKEEPER_HOME" {
#     # setup
#     stub_function "sys"

#     # execute
#     run configure_zookeeper_home

#     # assert
#     assert_no_error
#     assert_output_matches "ZOOKEEPER_HOME set to ${INSTALL_DIR}/zookeeper"
# }


# # test configure_core_site

# @test "configure_core_site creates a core-site.xml" {
#     # setup
#     ZOOKEEPER_CONF="${INSTALL_DIR}"

#     # execute
#     configure_core_site 2>&1 > /dev/null
#     run cat "${ZOOKEEPER_CONF}/core-site.xml"

#     # assert
#     assert_no_error
#     assert_output_matches "hdfs://localhost:9000"
# }

# # test configure_mapred_site

# @test "configure_mapred_site creates a mapred-site.xml" {
#     # setup
#     ZOOKEEPER_CONF="${INSTALL_DIR}"

#     # execute
#     configure_mapred_site 2>&1 > /dev/null
#     run cat "${ZOOKEEPER_CONF}/mapred-site.xml"

#     # assert
#     assert_no_error
#     assert_output_matches "localhost:9001"
# }

# # test configure_hdfs_site

# @test "configure_hdfs_site creates a hdfs-site.xml" {
#     # setup
#     ZOOKEEPER_CONF="${INSTALL_DIR}"
#     HDFS_DIR="blahblahblahdfs"

#     # execute
#     configure_hdfs_site 2>&1 > /dev/null
#     run cat "${ZOOKEEPER_CONF}/hdfs-site.xml"

#     # assert
#     assert_no_error
#     assert_output_matches "${HDFS_DIR}/data"
# }

# @test "configure_hdfs_site aborts if HDFS_DIR is not set" {
#     # setup
#     ZOOKEEPER_CONF="${INSTALL_DIR}"

#     # execute
#     run configure_hdfs_site

#     # assert
#     assert_error
#     assert_output_matches "You must have HDFS_DIR set to run setup_hdfs_site"
# }

# # test configure_zookeeper_env

# @test "configure_zookeeper_env creates a zookeeper-env.sh" {
#     # setup
#     ZOOKEEPER_CONF="${INSTALL_DIR}"
#     JAVA_HOME="somejavadir"

#     # execute
#     configure_zookeeper_env 2>&1 > /dev/null
#     run cat "${ZOOKEEPER_CONF}/zookeeper-env.sh"

#     # assert
#     assert_no_error
#     assert_output_matches "export JAVA_HOME=${JAVA_HOME}"
# }

# @test "configure_zookeeper_env aborts if JAVA_HOME not set" {
#     # setup
#     ZOOKEEPER_CONF="${INSTALL_DIR}"
#     unset JAVA_HOME

#     # execute
#     run configure_zookeeper_env

#     # assert
#     assert_error
#     assert_output_matches "You must have JAVA_HOME set to run setup_zookeeper_env"
# }

# # test configure_namenode

# @test "configure_namenode calls format" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"
#     ZOOKEEPER_HOME="${INSTALL_DIR}/blah-blah"

#     # execute
#     run configure_namenode

#     # assert
#     assert_no_error
#     assert_output_matches "${INSTALL_DIR}/blah-blah/bin/zookeeper namenode -format"
# }


# ###### end

# # test setup_zookeeper_home

# @test "setup_zookeeper_home creates symlink" {
#     # setup
#     eval "function sys() {
#         echo \"\$1\"
#     }"

#     # execute
#     run setup_zookeeper_home

#     # assert
#     assert_no_error
#     assert_output_matches "ln -s ${INSTALL_DIR}/zookeeper-${ZOOKEEPER_VERSION} ${INSTALL_DIR}/zookeeper"
# }

# @test "setup_zookeeper_home sets ZOOKEEPER_HOME" {
#     # setup
#     stub_function "sys"

#     # execute
#     run setup_zookeeper_home

#     # assert
#     assert_no_error
#     assert_output_matches "ZOOKEEPER_HOME set to ${INSTALL_DIR}/zookeeper"
# }
