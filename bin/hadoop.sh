# START hadoop.sh

# script local variables
HADOOP_HOME=""
HADOOP_CONF=""

install_hadoop() {
    if [ -z "$INSTALL_DIR" ] ; then
        abort "You must set INSTALL_DIR"
    fi
    if [ -z "$HADOOP_VERSION" ] ; then
        abort "You must set HADOOP_VERSION"
    fi
    if [ -z "$HADOOP_MIRROR" ] ; then
        abort "You must set HADOOP_MIRROR"
    fi
    if [ -z "$ARCHIVE_DIR" ] ; then
        abort "You must set ARCHIVE_DIR"
    fi
    if [ ! -w "$INSTALL_DIR" ]; then
        abort "The directory ${INSTALL_DIR} is not writable by you"
    fi
    ls ${INSTALL_DIR}/hadoop* 2> /dev/null && installed=true
    if [ "${installed}" == "true" ]; then
        abort "Looks like hadoop is already installed"
    fi
    local HADOOP_FILENAME="hadoop-${HADOOP_VERSION}.tar.gz"
    local HADOOP_SOURCE="${HADOOP_MIRROR}/${HADOOP_FILENAME}"
    local HADOOP_DEST="${ARCHIVE_DIR}/${HADOOP_FILENAME}"

    INDENT="  " && log
    light_blue "Installing Hadoop..." && INDENT="    "
    unarchive_hadoop_file
    configure_hadoop
    start_hadoop
    test_hadoop
}

unarchive_hadoop_file() {
    check_archive_file "${HADOOP_DEST}" "${HADOOP_SOURCE}"
    light_blue "Extracting file"
    sys "tar -xzf ${HADOOP_DEST} -C ${INSTALL_DIR}"
}

configure_hadoop() {
    # configure properties, these are very specific to the version
    light_blue "Configuring hadoop"
    INDENT="      "
    configure_hadoop_home
    configure_hadoop_conf
    configure_core_site
    configure_mapred_site
    configure_hdfs_site
    configure_hadoop_env
    configure_namenode
}

start_hadoop() {
    log ""
    light_blue "Starting hadoop"
    sys "${HADOOP_HOME}/bin/start-all.sh"
}

test_hadoop() {
    log ""
    light_blue "Testing hadoop"

    local hdfs_dir="/user/test"
    INDENT="        "
    light_blue "Creating a directory in hdfs"
    sys "${HADOOP_HOME}/bin/hadoop fs -mkdir ${hdfs_dir}"

    light_blue "Ensuring the directory was created"
    sys "${HADOOP_HOME}/bin/hadoop fs -ls ${hdfs_dir}"


    light_blue "Check looks good, removing directory"
    sys "${HADOOP_HOME}/bin/hadoop fs -rmr ${hdfs_dir}"

    INDENT="  "
    green "Hadoop is installed and running"
}

configure_hadoop_home() {
    local HADOOP_DIR="${INSTALL_DIR}/hadoop-${HADOOP_VERSION}"
    HADOOP_HOME="${INSTALL_DIR}/hadoop"
    sys "ln -s ${HADOOP_DIR} ${HADOOP_HOME}"
    light_blue "HADOOP_HOME set to ${HADOOP_HOME}"
}

configure_hadoop_conf() {
    if [ -z "$HADOOP_HOME" ]; then
        abort "You must set HADOOP_HOME to call configure_hadoop_conf"
    fi
    local HADOOP_CONF="${HADOOP_HOME}/conf"
    light_blue "HADOOP_CONF set to ${HADOOP_CONF}"
}

configure_core_site() {

    light_blue "Setting up core-site.xml"
    local CORE_SITE=$( cat <<-EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>fs.default.name</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF
)
    echo "${CORE_SITE}" > "${HADOOP_CONF}/core-site.xml"
}

configure_mapred_site() {
    light_blue "Setting up mapred-site.xml"
    local MAPRED_SITE=$( cat <<-EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapred.job.tracker</name>
        <value>localhost:9001</value>
    </property>
</configuration>
EOF
)
    echo "${MAPRED_SITE}" > "${HADOOP_CONF}/mapred-site.xml"
}

configure_hdfs_site() {
    light_blue "Setting up hdfs-site.xml"
    if [ -z "$HDFS_DIR" ]; then
        abort "You must have HDFS_DIR set to run setup_hdfs_site"
    fi
    local HDFS_SITE=$( cat <<-EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.name.dir</name>
        <value>${HDFS_DIR}/name</value>
        <final>true</final>
    </property>
    <property>
        <name>dfs.data.dir</name>
        <value>${HDFS_DIR}/data</value>
        <final>true</final>
    </property>
</configuration>

EOF
)
    echo "${HDFS_SITE}" > "${HADOOP_CONF}/hdfs-site.xml"
}

configure_hadoop_env() {
    light_blue "Setting up hadoop-env.sh"
    if [ -z "$JAVA_HOME" ]; then
        abort "You must have JAVA_HOME set to run setup_hadoop_env"
    fi
    local HADOOP_ENV=$( cat <<-EOF
# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME.  All others are
# optional.  When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# The java implementation to use.  Required.
export JAVA_HOME=${JAVA_HOME}
# export JAVA_HOME=/usr/lib/j2sdk1.5-sun

# Extra Java CLASSPATH elements.  Optional.
# export HADOOP_CLASSPATH=

# The maximum amount of heap to use, in MB. Default is 1000.
export HADOOP_HEAPSIZE=2000

# Extra Java runtime options.  Empty by default.
# export HADOOP_OPTS=-server

# Command specific options appended to HADOOP_OPTS when specified
export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_NAMENODE_OPTS"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_SECONDARYNAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_DATANODE_OPTS"
export HADOOP_BALANCER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_BALANCER_OPTS"
export HADOOP_JOBTRACKER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_JOBTRACKER_OPTS"
# export HADOOP_TASKTRACKER_OPTS=
# The following applies to multiple commands (fs, dfs, fsck, distcp etc)
# export HADOOP_CLIENT_OPTS

# Extra ssh options.  Empty by default.
# export HADOOP_SSH_OPTS="-o ConnectTimeout=1 -o SendEnv=HADOOP_CONF_DIR"

# Where log files are stored.  $HADOOP_HOME/logs by default.
# export HADOOP_LOG_DIR=${HADOOP_HOME}/logs

# File naming remote slave hosts.  $HADOOP_HOME/conf/slaves by default.
# export HADOOP_SLAVES=${HADOOP_HOME}/conf/slaves

# host:path where hadoop code should be rsync'd from.  Unset by default.
# export HADOOP_MASTER=master:/home/$USER/src/hadoop

# Seconds to sleep between slave commands.  Unset by default.  This
# can be useful in large clusters, where, e.g., slave rsyncs can
# otherwise arrive faster than the master can service them.
# export HADOOP_SLAVE_SLEEP=0.1

# The directory where pid files are stored. /tmp by default.
# export HADOOP_PID_DIR=/var/hadoop/pids

# A string representing this instance of hadoop. $USER by default.
# export HADOOP_IDENT_STRING=$USER

# The scheduling priority for daemon processes.  See 'man nice'.
# export HADOOP_NICENESS=10

EOF
)
    echo "${HADOOP_ENV}" > "${HADOOP_CONF}/hadoop-env.sh"
}

configure_namenode() {
    log ""
    light_blue "Formatting namenode"
    sys "${HADOOP_HOME}/bin/hadoop namenode -format"
}

# END hadoop.sh
