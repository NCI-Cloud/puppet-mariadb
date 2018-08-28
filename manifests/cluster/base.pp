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
  $wsrep_sst_password,
  $wsrep_sst_user,
  $package_names,
  $package_ensure,
  $debiansysmaint_password,
  $manage_repo,
  $repo_version,
  $manage_status,
  $status_user,
  $status_password,
  $config_hash,
  $enabled,
) inherits mariadb::params {

  class { 'mariadb::server':
    package_names           => $package_names,
    package_ensure          => $package_ensure,
    debiansysmaint_password => $debiansysmaint_password,
    repo_version            => $repo_version,
    manage_repo             => $manage_repo,
    config_hash             => $config_hash,
    enabled                 => $enabled,
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
      require         => Class['mariadb::server'],
    }
  }

}
