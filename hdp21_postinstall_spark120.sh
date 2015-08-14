#!/bin/bash

#
# Enable logging
#
exec >> "/var/log/post-install-spark120.out" 2>&1

wget http://fc595594b219777a4395-110c851fb29b5fda459c89608b6c18ea.r82.cf3.rackcdn.com/spark-1.2.0.2.2.0.0-82-bin-2.6.0.2.2.0.0-2041.tgz -O /tmp/spark-1.2.0.2.2.0.0-82-bin-2.6.0.2.2.0.0-2041.tgz || exit 1

mkdir -p /usr/hdp/2.2.0.0-2041/spark
mkdir -p /usr/hdp/current/
ln -s /usr/hdp/2.2.0.0-2041/spark /usr/hdp/current/spark

tar xvpf /tmp/spark-1.2.0.2.2.0.0-82-bin-2.6.0.2.2.0.0-2041.tgz -C /usr/hdp/current/spark/ --strip=1 || exit 1


if [ $(hostname) == "gateway-1" ]; then
  until su - hdfs -c 'hdfs dfs -mkdir -p /apps/spark/events'
  do
      sleep 5
  done

  su - hdfs -c 'hdfs dfs -chmod -R 777 /apps/spark/events'
  su - hdfs -c 'hdfs dfs -put /usr/hdp/current/spark/lib/spark-assembly-1.2.0.2.2.0.0-82-hadoop2.6.0.2.2.0.0-2041.jar /apps/spark/'
fi

cp -a /etc/hive/conf/hive-site.xml /usr/hdp/current/spark/conf/
sed -i 's/org.apache.hadoop.hive.ql.security.authorization.plugin.sqlstd.SQLStdConfOnlyAuthorizerFactory/org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider/g' /usr/hdp/current/spark/conf/hive-site.xml
sed -i 's/org.apache.hadoop.hive.ql.hooks.ATSHook//g' /usr/hdp/current/spark/conf/hive-site.xml
sed -i 's/<value>tez<\/value>/<value>mr<\/value>/g' /usr/hdp/current/spark/conf/hive-site.xml
sed -i 's/5s/5/g' /usr/hdp/current/spark/conf/hive-site.xml
sed -i 's/1800s/1800/g' /usr/hdp/current/spark/conf/hive-site.xml


cat > /etc/profile.d/spark.sh << END
export PATH=/usr/hdp/current/spark/bin:$PATH
alias spark-shell="MASTER=yarn-client command spark-shell"
alias pyspark="MASTER=yarn-client command pyspark"
alias run-example="EXAMPLE_MASTER=yarn-cluster command run-example"
END

cat > /usr/hdp/current/spark/conf/spark-env.sh << END
#!/usr/bin/env bash

# default to yarn-cluster mode, but make it overridable.
# setting spark.master in spark-defaults.conf doesn't allow overrides
if [ "\$MASTER" == "" ]; then
    export MASTER='yarn-cluster'
fi

# tell Spark where to find YARN configs
export YARN_CONF_DIR=/etc/hadoop/conf

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/hdp/current/share/lzo/0.6.0/lib/native/Linux-amd64-64
END

cat > /usr/hdp/current/spark/conf/spark-defaults.conf << END
spark.driver.extraJavaOptions -Dhdp.version=2.2.0.0-2041
spark.yarn.am.extraJavaOptions -Dhdp.version=2.2.0.0-2041

spark.eventLog.enabled              true
spark.eventLog.dir                  hdfs:///apps/spark/events
spark.serializer                    org.apache.spark.serializer.KryoSerializer

spark.yarn.jar                      hdfs:///apps/spark/spark-assembly-1.2.0.2.2.0.0-82-hadoop2.6.0.2.2.0.0-2041.jar

spark.executor.instances            2
spark.executor.memory               1501m
spark.driver.memory                 1024m
spark.python.worker.memory          1024m
spark.yarn.executor.memoryOverhead  256
spark.yarn.driver.memoryOverhead    256

spark.executor.extraClassPath       /usr/hdp/current/share/lzo/0.6.0/lib/hadoop-lzo-0.6.0.jar
spark.driver.extraClassPath         /usr/hdp/current/share/lzo/0.6.0/lib/hadoop-lzo-0.6.0.jar
END
