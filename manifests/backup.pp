# Class: mariadb::backup
#
# This module handles ...
#
# Parameters:
#   [*backupuser*]     - The name of the mariadb backup user.
#   [*backuppassword*] - The password of the mariadb backup user.
#   [*backupdir*]      - The target directory of the mariadbdump.
#   [*backupcompress*] - Boolean to compress backup with bzip2.
#   [*backupdays*]     - Number of days of backups to keep.
#   [*onefile*]        - Dump all DBs into one file?
#   [*ensure*]         - Specify if database backup is present or absent.
#   [*backupmethod*]   - Backup methods to select: mysqldump or mariabackup
#
# Actions:
#   GRANT SELECT, RELOAD, LOCK TABLES ON *.* TO 'user'@'localhost'
#    IDENTIFIED BY 'password';
#
# Requires:
#   Class['mariadb::config']
#
# Sample Usage:
#   class { 'mariadb::backup':
#     backupuser     => 'myuser',
#     backuppassword => 'mypassword',
#     backupdir      => '/tmp/backups',
#     backupcompress => true,
#     backupdays     => 30,
#   }
#
class mariadb::backup (
  String $backupuser,
  String $backuppassword,
  String $backupdir,
  Integer $backupdays = 30,
  Boolean $backupcompress = true,
  Boolean $onefile = true,
  String $ensure = 'present',
  Enum['mysqldump', 'mariabackup'] $backupmethod = 'mysqldump',
  Enum['zstd', 'gzip', 'xz', 'bzipd'] $compresstype = 'zstd',
  Boolean $compressparallel = false,
  Integer $compressthreads = Integer(min($facts['processors']['count']/2, 2)),
) {

  include ::mariadb

  database_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql_password($backuppassword),
    require       => Class['mariadb::server'],
  }

  if (versioncmp($::mariadb::version, '10.5') >= 0) {
    $grant = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'BINLOG MONITOR', 'PROCESS', 'SUPER' ]
  } else {
    $grant = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'REPLICATION CLIENT', 'PROCESS', 'SUPER' ]
  }
  mysql_grant { "${backupuser}@localhost/*.*":
    user       => "${backupuser}@localhost",
    table      => '*.*',
    privileges => $grant,
    require    => Database_user["${backupuser}@localhost"],
  }

  if $backupcompress {
    case $compresstype {
      'zstd': {
        ensure_packages(['zstd'])
        $compress_extension = 'zst'
        if $compressparallel {
          $compress_command = "pzstd -c -p ${compressthreads}"
        } else {
          $compress_command = 'zstd'
        }
      }
      'gzip': {
        ensure_packages(['gzip'])
        $compress_extension = 'gz'
        if $compressparallel {
          ensure_packages(['pigz'])
          $compress_command = "pigz -p ${compressthreads}"
        } else {
          $compress_command = 'gzip'
        }
      }
      'xz': {
        # unlike the other options, xz is packaged under different names on
        # Debian and RH
        ensure_packages([$mariadb::params::xz_package_name])
        $compress_extension = 'xz'
        if $compressparallel {
          ensure_packages(['pixz'])
          $compress_command = "pixz -p ${compressthreads}"
        } else {
          $compress_command = 'xz'
        }
      }
      'bzip2': {
        ensure_packages(['bzip2'])
        $compress_extension = 'bz2'
        if $compressparallel {
          ensure_packages(['pbzip2'])
          $compress_command = "pbzip2 -z -c -p${compressthreads}"
        } else {
          $compress_command = 'bzcat -z -c'
        }
      }
      default: {
          fail('Unknown compression type. Must be one of zstd, gzip, xz or bzip2')
      }
    }

  }

  if $backupmethod == 'mariabackup' {
    ensure_packages([$::mariadb::backup_package_name])
    $backupscript = 'mariabackup.sh'
  } else {
    $backupscript = 'mysqlbackup.sh'
  }

  cron { 'mysql-backup':
    ensure  => $ensure,
    command => "/usr/local/sbin/${backupscript}",
    user    => 'root',
    hour    => fqdn_rand(5),
    minute  => fqdn_rand(59),
    require => File[$backupscript],
  }

  $epp_params = {
    user => $backupuser,
    password => $backuppassword,
    backupdir => $backupdir,
    backupdays => $backupdays,
    onefile => $onefile,
    compress => $backupcompress,
    compress_command => $compress_command,
    compress_extension => $compress_extension,
  }

  file { $backupscript:
    ensure  => $ensure,
    path    => "/usr/local/sbin/${backupscript}",
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => epp("mariadb/${backupscript}.epp", $epp_params),
  }

  exec { "Create ${backupdir}":
    creates => $backupdir,
    command => "mkdir -p ${backupdir}",
    path    => $facts['path']
  } -> file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  }
}
