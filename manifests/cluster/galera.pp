# Class mariadb::cluster::galera
#
# Configure galera replication on the node.
#
# All parameters are identical to the mariadb::cluster namespace parameters.

class mariadb::cluster::galera (
  $cluster_peer,
  $wsrep_sst_password,
  $wsrep_sst_user,
  $wsrep_sst_method,
  $wsrep_cluster_name,
  $wsrep_slave_threads,
  $galera_name,
  $galera_ensure,
  $cluster_iface,
  $cluster_enabled=true,
  $wsrep_provider_options=undef,
) inherits mariadb::params {

  $service_name = $mariadb::params::service_name

  package { $galera_name:
    ensure => $galera_ensure,
    tag    => 'mariadb',
  }

  $wsrep_sst_auth = "${wsrep_sst_user}:${wsrep_sst_password}"

  if versioncmp($::facterversion, '2.4.6') > 0 {
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

  # there are enough differences in newer versions of galera to justify this
  #
  # Note that this may not work with 5.5, or with anything older than 10.0.
  # Removing support for older mariadb is something to leave for a 2.0 release.
  if versioncmp($mariadb::version, '10.2') >= 0 {
    $galera_template = 'galera_replication.cnf-10.2.erb'
  } elsif versioncmp($mariadb::version, '5.5') == 0 {
    $galera_template = 'galera_replication.cnf-5.5.erb'
  } else {
    $galera_template = 'galera_replication.cnf.erb'
  }
  # this is needed for the older template
  $mariadb_version = $mariadb::version
  file { "${mariadb::params::config_dir}/galera_replication.cnf":
    content => template("mariadb/${galera_template}"),
    require => Class['mariadb::server'],
  }

  exec { 'mariadb-galera-restart':
    command     => "service ${service_name} restart",
    logoutput   => on_failure,
    path        => '/sbin:/usr/sbin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => File["${mariadb::params::config_dir}/galera_replication.cnf"],
  }

  if $wsrep_sst_method == 'xtrabackup' or $wsrep_sst_method == 'xtrabackup-v2' {
    ensure_packages(['percona-xtrabackup'])
  }

}
