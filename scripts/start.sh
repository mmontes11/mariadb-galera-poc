#!/bin/bash

set -e

# TODO: use the 'hostname' command when migrating to Kubernetes
if [ -z "$HOSTNAME" ]; then
  echo "HOSTNAME environment variable not set"
  exit 1
fi

if [ -z "$ENTRYPOINT" ]; then
    ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"
fi

cat <<EOF | tee /etc/mysql/mariadb.conf.d/galera.cnf
[mysqld]
bind-address=0.0.0.0
default_storage_engine=InnoDB
binlog_format=row
innodb_autoinc_lock_mode=2

# Galera cluster configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://mariadb-0,mariadb-1"
wsrep_cluster_name="mariadb-galera-cluster"
wsrep_sst_method=rsync

# Cluster node configuration
wsrep_node_address="${HOSTNAME}"
wsrep_node_name="${HOSTNAME}
EOF

if [ "$HOSTNAME" = "mariadb-0" ]; then 
    bash -c "$ENTRYPOINT mariadbd --wsrep-new-cluster"
else
    bash -c "$ENTRYPOINT mariadbd"
fi