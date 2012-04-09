load test_helper

CMD="$BATS_TEST_DIRNAME/../bin/install.sh --no-run "
TMP_DIR="/tmp/ac-tes-install"
DEBUG=true # comment this out if you don't want the extra info, only shows debug for failures

setup() {
    mkdir "${TMP_DIR}"
}

teardown() {
    rm -rf "${TMP_DIR}"
}


@test "help option prints usage" {
    # execute
    run ${CMD} -h

    # assert
    assert_no_error
    assert_output_matches "Usage: "
}

@test "config_file option errors when arg does not exist" {
    # setup
    bad_file="${TMP_DIR}/somefile"

    # execute
    run $CMD -f "${bad_file}"

    # assert
    assert_error
    assert_output_matches "invalid config file, '${bad_file}' does not exist"
}

@test "config_file option sets CONFIG_FILE" {
    # setup
    good_file="${TMP_DIR}/somefile2"
    touch "${good_file}"

    # execute
    run $CMD -f "${good_file}"

    # assert
    assert_no_error
    assert_output_matches "CONFIG_FILE: ${good_file}"
}

@test "install dir option fails when directory exists" {
    # setup
    existing_dir="${TMP_DIR}/install_dir2"
    mkdir "${existing_dir}"

    # execute
    run $CMD -d "${existing_dir}"

    # assert
    assert_error
    assert_output_matches "Directory '${existing_dir}' already exists"
}

@test "install dir option sets INSTALL_DIR" {
    # setup
    new_dir="${TMP_DIR}/new_install_dir"

    # execute
    run $CMD -d "${new_dir}"

    # assert
    assert_output_matches "INSTALL_DIR: ${new_dir}"
}

@test "script when ARCHIVE_DIR exists" {
    # setup
    ARCHIVE_DIR="${TMP_DIR}/installer-archive"
    mkdir "${ARCHIVE_DIR}"

    # execute
    run ${CMD} -a "${ARCHIVE_DIR}"

    # assert
    assert_no_error
    assert_output_matches "Archive dir ${ARCHIVE_DIR} exists"
}

@test "script when ARCHIVE_DIR does not exist" {
    # setup
    ARCHIVE_DIR="${TMP_DIR}/installer-archive"

    # execute
    run ${CMD} -a "${ARCHIVE_DIR}"

    # assert
    assert_no_error
    assert_output_matches "Creating archive dir ${ARCHIVE_DIR}"
}
