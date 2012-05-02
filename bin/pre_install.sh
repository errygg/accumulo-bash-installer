
# START pre_install.sh

_uname() {
    # wrapper so I can replace in tests
    echo "$(uname)"
}

check_os() {
  # check os
    local PLATFORM=`_uname`
    light_blue "You are installing to OS: "
    case $PLATFORM in
        "Darwin") light_blue "${PLATFORM}" ;;
        "Linux") light_blue "${PLATFORM}" ;;
        *)
            abort "Installer does not support ${PLATFORM}"
    esac
}

check_config_file() {
    # check for a config file
    if [ -z $CONFIG_FILE ]; then
        light_blue  "No config file found, we will get them from you now"
    else
        light_blue "Using $CONFIG_FILE.  Here is the contents"
        cat "${CONFIG_FILE}"
        source "${CONFIG_FILE}"
    fi
}

get_install_dir() {
  # get install directory
    if [ -z $INSTALL_DIR ]; then
        while [ "${INSTALL_DIR}x" == "x" ]; do
            INSTALL_DIR=$(read_input "Enter install directory")
        done
    else
        light_blue "Install directory already set to ${INSTALL_DIR}"
    fi

  # check install direcotry
    if [ -d "$INSTALL_DIR" ]; then
        abort "Directory '${INSTALL_DIR}' already exists. You must install to a new directory."
    else
        light_blue "Creating directory ${INSTALL_DIR}"
        mkdir -p "${INSTALL_DIR}"
    fi
}

get_hdfs_dir() {
    if [ "${INSTALL_DIR}x" == "x" ]; then
        abort "INSTALL_DIR is not set"
    fi
    if [ ! -d "$INSTALL_DIR" ]; then
        abort "Install dir ${INSTALL_DIR} does not exist"
    fi
    # assign HDFS_DIR
    HDFS_DIR="${INSTALL_DIR}/hdfs"
    light_blue "Making HDFS directory ${HDFS_DIR}"
    mkdir "${HDFS_DIR}"
}

get_java_home() {
  # get java_home
    if [ -z $JAVA_HOME ]; then
        JAVA_HOME=$(read_input "Enter JAVA_HOME location")
    fi

  # check java_home
    if [ ! -d $JAVA_HOME ]; then
        abort "JAVA_HOME does not exist: ${JAVA_HOME}"
    else
        light_blue "JAVA_HOME set to ${JAVA_HOME}"
    fi
}

_hostname() {
    # wrapper so it can easily be replaced in testing
    echo $(hostname)
}

_ssh() {
    # wrapper so it can easily be replaced in testing
    # this function sets publickey as the only authentication, which is
    # the passwordless way Hadoop communicates in psuedo distributed mode
    echo $(ssh -o 'PreferredAuthentications=publickey' localhost "hostname")
}

check_ssh() {
  # check ssh localhost
    light_blue "Checking passwordless SSH (for Hadoop)"
    local HOSTNAME=$(_hostname)
    local SSH_HOST=$(_ssh)
    if [[ "${HOSTNAME}" == "${SSH_HOST}" ]]; then
        light_blue "SSH appears good"
    else
        abort "Problem with SSH, ran ssh -o 'PreferredAuthentications=publickey' localhost \"hostname\".  Expected ${HOSTNAME}, but got ${SSH_HOST}. Please see http://hadoop.apache.org/common/docs/r0.20.2/quickstart.html#Setup+passphraseless"
    fi
}

pre_install () {
    log
    INDENT="  "
    light_blue "Setting up configuration and checking requirements..."
    INDENT="    "

    check_os
    check_config_file
    get_install_dir
    get_hdfs_dir
    get_java_home
    check_ssh
  # TODO: ask which version of accumulo.  Need a good way to manage
}

# END pre_install.sh
