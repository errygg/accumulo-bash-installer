
# START pre_install.sh

_uname() {
    # wrapper so I can replace in tests
    echo "$(uname)"
}

check_os() {
  # check os
    local PLATFORM=`_uname`
    case $PLATFORM in
        "Darwin") yellow "You are installing to OS: ${PLATFORM}" "${INDENT}";;
        *)
            abort "Installer does not support ${PLATFORM}" "${INDENT}"
    esac
}

check_config_file() {
    # check for a config file
    if [ -n "${CONFIG_FILE}" ]; then
        yellow "Using $CONFIG_FILE.  Here is the contents" "${INDENT}"
        cat $CONFIG_FILE
        . $CONFIG_FILE
    else
        yellow  "No config file found, we will get them from you now" "${INDENT}"
    fi
}

set_install_dir() {
  # get install directory
    if [ -n "${INSTALL_DIR}" ]; then
    #TODO test this with configs and options
        yellow "Install directory set to ${INSTALL_DIR} by command line option" "${INDENT}"
    else
        while [ "${INSTALL_DIR}x" == "x" ]; do
            INSTALL_DIR=$(read_input "Enter install directory" "${INDENT}")
        done
    fi

  # check install direcotry
    if [ -d $INSTALL_DIR ]; then
        abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory." "${INDENT}"
    else
        yellow "Creating directory ${INSTALL_DIR}" "${INDENT}"
        mkdir -p "${INSTALL_DIR}"
    fi
}

set_hdfs_dir() {
      # assign HDFS_DIR
    HDFS_DIR="${INSTALL_DIR}/hdfs"
    yellow "Making HDFS directory ${HDFS_DIR}" "${INDENT}"
    mkdir -p "${HDFS_DIR}"

}

set_java_home() {
  # get java_home
    if [ ! -n "${JAVA_HOME}" ]; then
        JAVA_HOME=$(read_input "Enter JAVA_HOME location" "${INDENT}")
    fi

  # check java_home
    if [ ! -d $JAVA_HOME ]; then
        abort "JAVA_HOME does not exist: ${JAVA_HOME}" "${INDENT}"
    else
        yellow "JAVA_HOME set to ${JAVA_HOME}" "${INDENT}"
    fi
}

check_ssh() {
  # check ssh localhost
    yellow "Checking passwordless SSH (for Hadoop)" "${INDENT}"
    local HOSTNAME=$(hostname)
    local SSH_HOST=$(ssh -o 'PreferredAuthentications=publickey' localhost "hostname")
    if [[ "${HOSTNAME}" == "${SSH_HOST}" ]]; then
        yellow "SSH appears good" "${INDENT}"
    else
        abort "Problem with SSH, expected ${HOSTNAME}, but got ${SSH_HOST}. Please see http://hadoop.apache.org/common/docs/r0.20.2/quickstart.html#Setup+passphraseless" "${INDENT}"
    fi
}

pre_install () {
    log
    local INDENT="  "
    yellow "Setting up configuration and checking requirements..." "${INDENT}"
    INDENT="    "

    check_os
    check_config_file
    set_install_dir
    set_hdfs_dir
    set_java_home
    check_ssh
  # TODO: ask which version of accumulo.  Need a good way to manage
}

# END pre_install.sh
