# Configure mariadb cluster.
#
# Deprecated! Use mariadb::cluster::galera instead!
class mariadb::cluster::config (
  String $wsrep_cluster_name = $::mariadb::cluster::wsrep_cluster_name,
  String $wsrep_sst_auth = $::mariadb::cluster::wsrep_sst_auth,
  String $wsrep_sst_method = $::mariadb::cluster::wsrep_sst_method,
  Integer $wsrep_slave_threads = $::mariadb::cluster::wsrep_slave_threads,
  String $config_dir = $mariadb::params::config_dir,
) inherits mariadb::params {

  warning('mariadb::cluster::config is deprecated - please use mariadb::cluster::galera')
  include ::mariadb
  $maria_version = $::mariadb::version

  class { 'mariadb::cluster::galera':
    cluster_peer           => $::mariadb::cluster::cluster_peer,
    wsrep_sst_password     => $::mariadb::cluster::wsrep_sst_password,
    wsrep_sst_method       => $wsrep_sst_method,
    wsrep_cluster_name     => $wsrep_cluster_name,
    wsrep_slave_threads    => $wsrep_slave_threads,
    galera_name            => $::mariadb::cluster::galera_name,
    galera_ensure          => $::mariadb::cluster::galera_ensure,
    cluster_enabled        => $::mariadb::cluster::cluster_enabled,
    wsrep_provider_options => $::mariadb::cluster::wsrep_provider_options,
  }

}
