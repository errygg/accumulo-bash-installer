load test_helper

CMD="$BATS_TEST_DIRNAME/../bin/install.sh --no-run"
DEBUG=true # comment this out if you don't want the extra info, only shows debug for failures

setup() {
    . $CMD > /dev/null
    stub_function "pre_install"
    stub_function "install_hadoop"
    stub_function "install_zookeeper"
    stub_function "install_accumulo"
    stub_function "post_install"
}

test_function_called() {
     fname=$1
     # setup
     local msg="$fname called"
     stub_function "$fname" "${msg}" 1

     # execute
     run install

     # assert
     assert_output_matches "${msg}"
}

@test "test install calls pre_install" {
    test_function_called "pre_install"
}

@test "test install calls install_hadoop" {
    test_function_called "install_hadoop"
}

@test "test install calls install_zookeeper" {
    test_function_called "install_zookeeper"
}

@test "test install calls install_accumulo" {
    test_function_called "install_accumulo"
}

@test "test install calls post_install" {
    test_function_called "post_install"
}

@test "test that travis catches my failures correctly" {
    false
}
