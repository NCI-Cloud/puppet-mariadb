# Create a MySQL/MariaDB config file from a config hash.
#
# This is intended to provide a mechanism for setting up conf.d files, either
# under /etc/mysql/conf.d/ or .../mariadb.conf.d/ - this is a more flexible
# mechanism for managing configuration than a single-file template for my.cnf.
#
# Keys must be a simple string. Values may be either single strings or arrays
# of strings - in the latter case the key is repeated with each of the
# elements in the array as the value. No attempt is made to validate the
# contents - this is on the user.
# 
# Files are created with name "${dir}/${order}-${name}.cnf"
#
# Parameters:
#
#  [*dir*]         - conf.d directory in which to create this file
#  [*order*]       - ordering value for this file (Integer)
#  [*description*] - description string for the file
#  [*sections*]    - hash containing section => key=value mappings
#  [*ensure*]      - whether the config file should exist
#
# Usage example:
#
#  mariadb::config_file { 'galera_replication':
#    dir         => '/etc/mysql/config.d',
#    order       => 99,
#    description => 'Galera replication configuration',
#    sections    => {
#      galera => {
#        wsrep_on => 'ON',
#        wsrep_provider => '/usr/lib/galera/libgalera_smm.so',
#        ...
#      }
#    }
#  }
#
# This would result in:
#
#  # Managed by puppet - local changes will be lost!
#  [galera]
#  wsrep_on = ON
#  wsrep_provider = /usr/lib/galera/libgalera_smm.so
#  ...
#
#
define mariadb::config_file(
  String $dir,
  Integer $order,
  String $description,
  Hash[
    String, Hash[
      String, Variant[
        String,
        Array[ String ]
      ]
    ]
  ] $sections,
  Enum['present', 'absent'] $ensure = present,
) {
  
  $epp_params = {
    description => $description,
    sections => $sections,
  }

  # the conf.d directory needs to exist regardless of the state of this file
  file { $dir:
    ensure => directory,
  }
  -> file { "${dir}/${order}-${name}.cnf":
    ensure  => $ensure,
    group   => $mariadb::params::root_group,
    mode    => '0644',
    content => epp('mariadb/conf.d.epp', $epp_params),
    require => File[$dir],
    tag     => ['mariadb-config'],
  }
}
