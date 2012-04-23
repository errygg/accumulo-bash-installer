# START zookeeper.sh

# script local variables
ZOOKEEPER_HOME=""
ZOOKEEPER_CONF=""

install_zookeeper() {
    if [ -z "$INSTALL_DIR" ] ; then
        abort "You must set INSTALL_DIR"
    fi
    if [ -z "$ZOOKEEPER_VERSION" ] ; then
        abort "You must set ZOOKEEPER_VERSION"
    fi
    if [ -z "$ZOOKEEPER_MIRROR" ] ; then
        abort "You must set ZOOKEEPER_MIRROR"
    fi
    if [ -z "$ARCHIVE_DIR" ] ; then
        abort "You must set ARCHIVE_DIR"
    fi
    if [ ! -w "$INSTALL_DIR" ]; then
        abort "The directory ${INSTALL_DIR} is not writable by you"
    fi
    ls ${INSTALL_DIR}/zookeeper* 2> /dev/null && installed=true
    if [ "${installed}" == "true" ]; then
        abort "Looks like zookeeper is already installed"
    fi
    local ZOOKEEPER_FILENAME="zookeeper-${ZOOKEEPER_VERSION}.tar.gz"
    local ZOOKEEPER_SOURCE="${ZOOKEEPER_MIRROR}/${ZOOKEEPER_FILENAME}"
    local ZOOKEEPER_DEST="${ARCHIVE_DIR}/${ZOOKEEPER_FILENAME}"

    INDENT="  " && log
    light_blue "Installing Zookeeper..." && INDENT="    "
    unarchive_zookeeper_file
    configure_zookeeper
    start_zookeeper
    test_zookeeper
}

unarchive_zookeeper_file() {
    check_archive_file "${ZOOKEEPER_DEST}" "${ZOOKEEPER_SOURCE}"
    light_blue "Extracting file"
    sys "tar -xzf ${ZOOKEEPER_DEST} -C ${INSTALL_DIR}"
}

configure_zookeeper() {
    light_blue "Configuring zookeeper"
    INDENT="      "
    local ZOOKEEPER_CONF="${ZOOKEEPER_HOME}/conf"
    light_blue "ZOOKEEPER_CONF set to ${ZOOKEEPER_CONF}"
    configure_zookeeper_data_dir
    configure_zookeeper_home
    configure_zoo_cfg
}

start_zookeeper() {
    a=1
}

test_zookeeper() {
    a=1
}

configure_zookeeper_data_dir() {
    a=1
}

configure_zookeeper_home() {
    # setup directory
    local ZOOKEEPER_DIR="${INSTALL_DIR}/zookeeper-${ZOOKEEPER_VERSION}"
    ZOOKEEPER_HOME="${INSTALL_DIR}/zookeeper"
    sys "ln -s ${ZOOKEEPER_DIR} ${ZOOKEEPER_HOME}"
    light_blue "ZOOKEEPER_HOME set to ${ZOOKEEPER_HOME}"
}

configure_zoo_cfg() {
    a=1
}

# END zookeeper.sh
