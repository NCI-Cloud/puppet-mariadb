# Class mariadb::cluster::galera
#
# Configure galera replication on the node.
#
# All parameters are identical to the mariadb::cluster namespace parameters.
class mariadb::cluster::galera (
  String $cluster_peer,
  String $wsrep_sst_password,
  String $wsrep_sst_user,
  String $wsrep_sst_method,
  String $wsrep_cluster_name,
  Integer $wsrep_slave_threads,
  String $galera_name,
  String $galera_ensure,
  String $cluster_iface,
  Boolean $cluster_enabled=true,
  Optional[String] $wsrep_provider_options=undef,
) inherits mariadb::params {

  $service_name = $mariadb::params::service_name
  $config_dir = $mariadb::params::config_dir

  # packages - galera, and socat (for replication)
  package { $galera_name:
    ensure => $galera_ensure,
    tag    => 'mariadb',
  }

  package { 'socat':
    ensure => 'present',
  }

  # the basic options
  #
  # clustered or not?
  if versioncmp($mariadb::version, '5.5') > 0 {
    if $cluster_enabled {
      $cluster_options = { wsrep_on => 'ON' }
    } else {
      $cluster_options = { wsrep_on => 'OFF' }
    }
  } else {
    $cluster_options = {
      '# galera in mariadb 5.5 is always on if the module is available' => undef,
    }
  }

  # wsrep provider and options
  $base_provider_options = {
    wsrep_provider => $mariadb::params::wsrep_provider,
  }
  if $wsrep_provider_options {
    $provider_options = $base_provider_options + { wsrep_provider_options => $wsrep_provider_options }
  } else {
    $provider_options = $base_provider_options
  }

  # general wsrep configuration
  $common_wsrep_options = {
    wsrep_node_name => $facts['networking']['hostname'],
    wsrep_cluster_address => "gcomm://${cluster_peer}",
    wsrep_cluster_name => $wsrep_cluster_name,
    wsrep_sst_auth => "${wsrep_sst_user}:${wsrep_sst_password}",
    wsrep_sst_method => $wsrep_sst_method,
    wsrep_slave_threads => $wsrep_slave_threads,
  }

  # node address/interface configuration 
  if versioncmp($facts['facterversion'], '2.4.6') > 0 {
    # if the cluster interface doesn't exist there isn't much we can do here,
    # except bail and hope that a subsequent puppet run will fix things
    if $::facts['networking']['interfaces'][$cluster_iface] {
      $ipaddress_cluster_iface = $::facts['networking']['interfaces'][$cluster_iface]['ip']
    } else {
      $ipaddress_cluster_iface = ''
    }
  } else {
    $ipaddress_cluster_iface = lookup("ipaddress_${cluster_iface}")
  }
  $node_wsrep_options = {
    wsrep_node_address => $ipaddress_cluster_iface,
    wsrep_node_incoming_address => $ipaddress_cluster_iface,
  }
  $wsrep_options = $common_wsrep_options + $node_wsrep_options

  # server options
  $common_server_options = {
    binlog_format => 'ROW',
    default_storage_engine => 'InnoDB',
    innodb_autoinc_lock_mode => '2',
  }

  # version specific bits
  if versioncmp($mariadb::version, '10.2') >= 0 {
    $server_options = $common_server_options
    $section_name = 'galera'
  } elsif versioncmp($mariadb::version, '5.5') > 0 {
    $server_options =  $common_server_options + { innodb_locks_unsafe_for_binlog => '1' }
    $section_name = 'galera'
  } else {
    # old mariadb is weird
    $server_options = $common_server_options
    $section_name = 'mysqld'
  }

  # all collected into a single hash to go in the galera section
  $galera_options = $cluster_options + $provider_options + $wsrep_options + $server_options

  $base_sections = {
    "${section_name}" => $galera_options,
  }

  # now the xtrabackup section, if we need it
  # 
  # Note: the xtrabackup/xtrabackup-v2 methods are not supported as of 10.3!
  case $wsrep_sst_method {
    'xtrabackup', 'xtrabackup-v2': {
      if versioncmp($mariadb::version, '10.2') > 0 {
        fail('percona-xtrabackup is no longer compatible with Mariadb as of 10.3')
      }
      package { 'percona-xtrabackup':
        ensure => $galera_ensure,
      }

      $sst_options = {
        streamfmt => 'xbstream',
        datadir => '/var/lib/mysql',
      }
      $sections = $base_sections + { 'sst' => $sst_options }
    }
    'mariabackup': {
      package { $mariadb::backup_package_name:
        ensure => $galera_ensure,
      }
      $sections = $base_sections
    }
    default: {
      $sections = $base_sections
    }
  }
  mariadb::config_file { 'galera_replication':
    ensure      => present,
    dir         => $config_dir,
    order       => 80,
    description => 'Galera Replication configuration file.',
    sections    => $sections,
    require     => Class['mariadb::server'],
  }
  ~> exec { 'mariadb-galera-restart':
    command     => "service ${service_name} restart",
    logoutput   => on_failure,
    path        => '/sbin:/usr/sbin:/usr/bin:/bin/',
    refreshonly => true,
  }

  # clean up of the old galera_replication.cnf
  file { "${config_dir}/galera_replication.cnf":
    ensure => absent,
  }

}
