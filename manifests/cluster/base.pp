# Class: mariadb::cluster::base
#
# perform the basic initialisation of a cluster node - install packages, bring
# up the server stand alone, configure the basic user accounts, and leave
# the node in a state where it's ready to have galera installed and configured.
#
# All parameters are identical to the mariadb::cluster namespace parameters.
#
#
class mariadb::cluster::base (
  String $wsrep_sst_password,
  String $wsrep_sst_user,
  Array[String] $package_names,
  String $package_ensure,
  Optional[String] $debiansysmaint_password,
  Boolean $manage_status,
  String $status_user,
  String $status_password,
  Enum['cluster', 'standalone'] $status_type,
  Hash[String, Any] $config_hash,
  Boolean $enabled,
  Boolean $manage_service,
) inherits mariadb::params {

  class { 'mariadb::server':
    package_names           => $package_names,
    package_ensure          => $package_ensure,
    debiansysmaint_password => $debiansysmaint_password,
    config_hash             => $config_hash,
    enabled                 => $enabled,
    manage_service          => $manage_service,
  }

  class { 'mariadb::cluster::auth':
    wsrep_sst_user     => $wsrep_sst_user,
    wsrep_sst_password => $wsrep_sst_password,
  }

  if $manage_status == true {
    if $status_password == undef {
      fail('Must specify status_password to manage cluster status')
    }

    class { 'mariadb::cluster::status':
      status_user     => $status_user,
      status_password => $status_password,
      status_type     => $status_type,
      require         => Class['mariadb::server'],
    }
  }

}
