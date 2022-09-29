class mariadb::cluster::config (
  $wsrep_cluster_name,
  $wsrep_sst_auth,
  $wsrep_sst_method,
  $wsrep_slave_threads,
  $config_dir           = $mariadb::params::config_dir,
) inherits mariadb::params {

  warning('mariadb::cluster::config is deprecated - please use mariadb::cluster::galera')
  include ::mariadb
  $maria_version = $::mariadb::version

  file { "${config_dir}/galera_replication.cnf":
    content => template('mariadb/galera_replication.cnf.erb'),
  }

}
