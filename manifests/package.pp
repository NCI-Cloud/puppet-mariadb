# Class: mariadb::packages
#
#   This class installs mariadb client software.
#
class mariadb::package($package_names, $package_ensure) {

  package { $package_names:
    ensure => $package_ensure,
    tag    => 'mariadb',
  }
}
