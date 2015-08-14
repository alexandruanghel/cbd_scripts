#!/bin/bash

#
# Enable logging
#
exec >> "/var/log/post-install-hue.out" 2>&1

if [ $(hostname) == "gateway-1" ]; then

    yum -y install hue
    sed -i "s/secret_key=.*$/secret_key=$(openssl rand 32 | sha224sum | head -c 56)/" /etc/hue/conf/hue.ini
    sed -i "s/fs_defaultfs=.*$/fs_defaultfs=hdfs:\/\/master-1.local:8020/" /etc/hue/conf/hue.ini
    sed -i "s/webhdfs_url=.*$/webhdfs_url=http:\/\/master-1.local:50070\/webhdfs\/v1\//" /etc/hue/conf/hue.ini
    sed -i "s/resourcemanager_api_url=.*$/resourcemanager_api_url=http:\/\/master-1.local:8088/" /etc/hue/conf/hue.ini
    sed -i "s/resourcemanager_rpc_url=.*$/resourcemanager_rpc_url=http:\/\/master-1.local:8050/" /etc/hue/conf/hue.ini
    sed -i "s/proxy_api_url=.*$/proxy_api_url=http:\/\/master-1.local:8088/" /etc/hue/conf/hue.ini
    sed -i "s/history_server_api_url=.*$/history_server_api_url=http:\/\/secondary-1.local:19888/" /etc/hue/conf/hue.ini
    sed -i "s/oozie_url=.*$/oozie_url=http:\/\/secondary-1.local:11000\/oozie/" /etc/hue/conf/hue.ini
    sed -i "s/hive_server_host=.*$/hive_server_host=gateway-1.local/" /etc/hue/conf/hue.ini
    sed -i "s/templeton_url=.*$/templeton_url=http:\/\/gateway-1.local:50111\/templeton\/v1\//" /etc/hue/conf/hue.ini

    until su - hdfs -c 'hdfs dfs -mkdir /user/hue'
    do
        sleep 5
    done

    until su - hdfs -c 'hdfs dfs -chown hue:hue /user/hue'
    do
        sleep 5
    done

    service hue start
fi
