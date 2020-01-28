#!/bin/bash

spool_dir="/var/spool/wavefront-proxy"
mkdir -p $spool_dir

# Be receptive to core dumps
ulimit -c unlimited

# Allow high connection count per process (raise file descriptor limit)
ulimit -Sn 65536
ulimit -Hn 65536

java_heap_usage=${JAVA_HEAP_USAGE:-4G}
jvm_initial_ram_percentage=${JVM_INITIAL_RAM_PERCENTAGE:-50.0}
jvm_max_ram_percentage=${JVM_MAX_RAM_PERCENTAGE:-85.0}

# Use cgroup opts - Note that -XX:UseContainerSupport=true since Java 8u191.
# https://bugs.openjdk.java.net/browse/JDK-8146115
jvm_container_opts="-XX:InitialRAMPercentage=$jvm_initial_ram_percentage  -XX:MaxRAMPercentage=$jvm_max_ram_percentage"
if [ "${JVM_USE_CONTAINER_OPTS}" = false ] ; then
    jvm_container_opts="-Xmx$java_heap_usage -Xms$java_heap_usage"
fi

java \
    $jvm_container_opts $JAVA_ARGS \
	-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager \
	-Dlog4j.configurationFile=/etc/wavefront/wavefront-proxy/log4j2.xml \
	-jar /opt/wavefront/wavefront-proxy/bin/wavefront-push-agent.jar \
	-h $WAVEFRONT_URL \
	-t $WAVEFRONT_TOKEN \
	--hostname ${WAVEFRONT_HOSTNAME:-$(hostname)} \
	--ephemeral true \
	--buffer ${spool_dir}/buffer \
	--flushThreads 6 \
	$WAVEFRONT_PROXY_ARGS
