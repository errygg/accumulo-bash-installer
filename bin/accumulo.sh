# START accumulo.sh

ACCUMULO_HOME=""
ACCUMULO_CONF=""

install_accumulo() {

    if [ -z "$INSTALL_DIR" ] ; then
        abort "You must set INSTALL_DIR"
    fi

    if [ -z "$ACCUMULO_VERSION" ] ; then
        abort "You must set HADOOP_VERSION"
    fi

    if [ -z "$ACCUMULO_MIRROR" ] ; then
        abort "You must set HADOOP_MIRROR"
    fi

    if [ -z "$ARCHIVE_DIR" ] ; then
        abort "You must set ARCHIVE_DIR"
    fi

    if [ ! -w "$INSTALL_DIR" ]; then
        abort "The directory ${INSTALL_DIR} is not writable by you"
    fi

    ls ${INSTALL_DIR}/accumulo* 2> /dev/null && installed=true

    if [ "${installed}" == "true" ]; then
        abort "Looks like accumulo is already installed"
    fi

    local ACCUMULO_FILENAME="accumulo-${ACCUMULO_VERSION}-dist.tar.gz"
    local ACCUMULO_SOURCE="${ACCUMULO_MIRROR}/${ACCUMULO_FILENAME}"
    local ACCUMULO_DEST="${ARCHIVE_DIR}/${ACCUMULO_FILENAME}"

    INDENT="  " && log

    light_blue "Installing Accumulo..." && INDENT="    "
    unarchive_accumulo_file
    configure_accumulo
    start_accumulo
    test_accumulo
}

unarchive_accumulo_file() {
    check_archive_file "${ACCUMULO_DEST" "${ACCUMULO_SOURCE}"
    light_blue "Extracting file"
    sys "tar xzf ${ACCUMULO_DEST} -C ${INSTALL_DIR}"
}

configure_accumulo() {
    light_blue "Configuring accumulo"
    INDENT="      "
}

start_accumulo() {
    log ""
    light_blue "Starting accumulo"
    sys "${ACCUMULO_HOME}/bin/start-all.sh"
}

test_accumulo() {
    log ""
    light_blue "Testing accumulo"
    # TODO - Test that accumulo works here
}

configure_accumulo_home() {
    local ACCUMULO_DIR="${INSTALL_DIR}/accumulo-${ACCUMULO_VERSION}"
    ACCUMULO_HOME="${INSTALL_DIR}/accumulo"
    sys "ln -s ${ACCUMULO_DIR} ${ACCUMULO_HOME}"
    light_blue "ACCUMULO_HOME set to ${ACCUMULO_HOME}"
}

configure_accumulo_conf() {
    if [ -z "$ACCUMULO_HOME" ]; then
        abort "You must set ACCUMULO_HOME to call configure_accumulo_conf"
    fi
    ACCUMULO_CONF="${ACCUMULO_HOME}/conf"
    light_blue "ACCUMULO_CONF set to ${ACCUMULO_CONF}"
}

# END accumulo.sh
