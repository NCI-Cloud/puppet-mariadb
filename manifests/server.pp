# Class: mariadb::server
#
# manages the installation of the mariadb server.  manages the package, service,
# my.cnf
#
# Parameters:
#   [*package_ensure*]
#     Ensure value for the server packages. Set to `present` or a version number.
#   [*package_names*]
#     Array of names of the mariadb server packages.
#   [*service_name*]
#     Name of the mariadb service
#   [*service_provider*]
#     Service type's provider
#   [*config_hash*]
#     hash of config parameters that need to be set.
#   [*enabled*]
#     If true, enable the service to start on boot.
#   [*manage_service*]
#     If true, manage the service.
#   [*mirror*]
#     Set the URL to the download mirror (Note: All but the operatingsystem /debian|/ubuntu)
#   [*config_hash*]   - hash of config parameters that need to be set.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mariadb::server (
  String $package_ensure         = $mariadb::params::server_package_ensure,
  Array[String] $package_names   = $mariadb::params::server_package_names,
  String $service_name           = $mariadb::params::service_name,
  Optional[String] $service_provider = $mariadb::params::service_provider,
  Optional[String] $debiansysmaint_password = undef,
  Hash[String, Any] $config_hash = {},
  Boolean $enabled               = true,
  Boolean $manage_service        = true,
) inherits mariadb::params {

  include ::mariadb

  Class['mariadb::server'] -> Class['mariadb::config']

  $config_class = { 'mariadb::config' => $config_hash }

  create_resources( 'class', $config_class )

  package { $package_names:
    ensure => $package_ensure,
    tag    => 'mariadb',
  }

  file { '/var/log/mysql/error.log':
    owner   => mysql,
    require => Package[$package_names],
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $manage_service {
    $piddir = dirname($mariadb::params::pidfile)

    file { $piddir:
      ensure  => directory,
      owner   => 'mysql',
      group   => 'root',
      mode    => '0755',
      require => Package[$package_names],
    }

    -> service { 'mariadb':
      ensure   => $service_ensure,
      name     => $service_name,
      enable   => $enabled,
      require  => Package[$package_names],
      provider => $service_provider,
    }
  }
}
