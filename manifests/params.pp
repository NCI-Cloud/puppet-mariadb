# Class: mariadb::params
#
#   The mariadb configuration settings.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mariadb::params {

  $bind_address        = '127.0.0.1'
  $port                = 3306
  $etc_root_password   = false
  $ssl                 = false
  $restart             = true
  $slave_threads       = $::processorcount * 2
  $repo_version        = '5.5'

  # default config options
  $max_connections     = 100
  $tmp_table_size      = '32M'
  $max_heap_table_size = '32M'
  $query_cache_limit   = '128k'
  $query_cache_size    = '64M'
  $skip_name_resolve   = undef

  case $::osfamily {
    'RedHat': {
      $basedir                = '/usr'
      $datadir                = '/var/lib/mysql'
      $tmpdir                 = '/tmp'
      $service_name           = 'mysql'
      $client_package_names   = ['MariaDB-client']
      $client_package_ensure  = 'installed'
      $server_package_names   = ['MariaDB-server']
      $cluster_package_names  = ['MariaDB-Galera-server']
      $cluster_package_ensure = 'installed'
      $galera_package_name    = 'galera'
      $socket                 = '/var/lib/mysql/mysql.sock'
      $pidfile                = '/var/run/mysqld/mysqld.pid'
      $config_file            = '/etc/my.cnf'
      $config_dir             = '/etc/my.cnf.d'
      $log_error              = '/var/log/mysqld.log'
      $ruby_package_name      = 'ruby-mysql'
      $ruby_package_provider  = 'gem'
      $python_package_name    = 'MySQL-python'
      $php_package_name       = 'php-mysql'
      $java_package_name      = 'mysql-connector-java'
      $root_group             = 'root'
      $ssl_ca                 = "${config_dir}/cacert.pem"
      $ssl_cert               = "${config_dir}/server-cert.pem"
      $ssl_key                = "${config_dir}/server-key.pem"
      $repo_class             = 'mariadb::repo::redhat'
      $wsrep_provider         = '/usr/lib64/galera/libgalera_smm.so'
      $default_mirror         = '"http://yum.mariadb.org'
    }

    'Debian': {
      $basedir                = '/usr'
      $datadir                = '/var/lib/mysql'
      $tmpdir                 = '/tmp'
      if $::lsbdistid == 'Ubuntu' and versioncmp($::operatingsystemrelease, '16.04') >= 0 {
        $service_name         = 'mysql'
        $cluster_package_names  = ['mariadb-galera-server']
        $galera_package_name    = 'galera-3'
      } elsif $::lsbdistid == 'Ubuntu' and versioncmp($::operatingsystemrelease, '18.04') >= 0 {
        $service_name         = 'mariadb'
        $cluster_package_names  = ['mariadb-server']
        $galera_package_name    = 'galera-3'
      } else {
        $service_name           = 'mysql'
        $cluster_package_names  = ['mariadb-galera-server']
        $galera_package_name    = 'galera'
      }
      $client_package_names   = ['libmysqlclient18', 'mysql-common', 'mariadb-client']
      $client_package_ensure  = 'installed'
      $server_package_names   = ['mariadb-server']
      $cluster_package_ensure = 'installed'
      $socket                 = '/var/run/mysqld/mysqld.sock'
      $pidfile                = '/var/run/mysqld/mysqld.pid'
      $config_file            = '/etc/mysql/my.cnf'
      $config_dir             = '/etc/mysql/conf.d'
      $log_error              = '/var/log/mysql/error.log'
      $ruby_package_name      = 'libmysql-ruby'
      $python_package_name    = 'python-mysqldb'
      $php_package_name       = 'php5-mysql'
      $java_package_name      = 'libmysql-java'
      $root_group             = 'root'
      $ssl_ca                 = "${config_dir}/cacert.pem"
      $ssl_cert               = "${config_dir}/server-cert.pem"
      $ssl_key                = "${config_dir}//server-key.pem"
      $repo_class             = 'mariadb::repo::debian'
      $wsrep_provider         = '/usr/lib/galera/libgalera_smm.so'
      $default_mirror         = 'http://mirror.aarnet.edu.au/pub/MariaDB'
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat, Debian")
    }
  }

}
