# START hadoop.sh

install_hadoop() {
    INDENT="  "

    # hadoop archive file
    local HADOOP_FILENAME="hadoop-${HADOOP_VERSION}.tar.gz"
    local HADOOP_SOURCE="${HADOOP_MIRROR}/${HADOOP_FILENAME}"
    local HADOOP_DEST="${ARCHIVE_DIR}/${HADOOP_FILENAME}"

    log
    light_blue "Installing Hadoop..."
    INDENT="    "
    ensure_file "${HADOOP_DEST}" "${HADOOP_SOURCE}"

    # install from archive
    light_blue "Extracting ${HADOOP_DEST} to ${INSTALL_DIR}"
    sys "tar -xzf ${HADOOP_DEST} -C ${INSTALL_DIR}"

    # setup directory
    local HADOOP_DIR="${INSTALL_DIR}/hadoop-${HADOOP_VERSION}"
    local HADOOP_HOME="${INSTALL_DIR}/hadoop"
    light_blue "Setting up ${HADOOP_HOME}" "${INDENT}"
    sys "ln -s ${HADOOP_DIR} ${HADOOP_HOME}"

    # configure properties, these are very specific to the version
    light_blue "Configuring hadoop"
    INDENT="      "
    local HADOOP_CONF="${HADOOP_HOME}/conf"

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

    light_blue "Setting up hdfs-site.xml"
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

    light_blue "Setting up hadoop-env.sh"
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

    # format hdfs
    light_blue "Formatting namenode"
    sys "${HADOOP_HOME}/bin/hadoop namenode -format"

    # start hadoop
    log ""
    light_blue "Starting hadoop"
    sys "${HADOOP_HOME}/bin/start-all.sh"

    # test installation
    log ""
    light_blue "Testing hadoop"
    INDENT="        "
    light_blue "Creating a /user/test directory in hdfs"
    sys "${HADOOP_HOME}/bin/hadoop fs -mkdir /user/test"

    light_blue "Ensure the directory was created with 'fs -ls /user'"
    local hadoop_check=$("${HADOOP_HOME}/bin/hadoop" fs -ls /user)
    if [[ "${hadoop_check}" =~ .*/user/test ]]; then
        light_blue "Check looks good, removing directory"
        sys "${HADOOP_HOME}/bin/hadoop fs -rmr /user/test"
    else
        abort "Unable to create the directory in HDFS"
    fi

    INDENT="  "
    green "Hadoop is installed and running"
}

# END hadoop.sh
