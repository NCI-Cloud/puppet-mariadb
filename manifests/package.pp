# Class: mariadb::packages
#
#   This class installs mariadb client software.
#
class mariadb::package(
  Array[String] $package_names = $::mariadb::params::client_package_names,
  String $package_ensure = $::mariadb::params::client_package_ensure,
) inherits mariadb::params {

  package { $package_names:
    ensure => $package_ensure,
    tag    => 'mariadb',
  }
}
