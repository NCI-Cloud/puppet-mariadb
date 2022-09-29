# Configure status check support for the cluster
class mariadb::cluster::status (
  String $status_user,
  String $status_password,
  Enum['cluster', 'standalone'] $status_type='cluster',
) {

  # The cluster check script verifies that a node is synchronised and a proper
  # cluster member, the standalone check script simply verifies that the
  # server is accessible and responding to queries.
  #
  # Note: default is unnecessary as this is testing against an enumerated
  # type, but is there to shut up warnings.
  case $status_type {
    'cluster':    { $clustercheck = 'mariadb/clustercheck.erb' }
    'standalone': { $clustercheck = 'mariadb/clustercheck-standalone.erb' }
    default: {}
  }

  file { '/usr/local/bin/clustercheck':
    content => template($clustercheck),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/local/bin/clustercheck-maintenance':
    source => 'puppet:///modules/mariadb/clustercheck-maintenance.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  augeas { 'mysqlchk':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '9200']/port 9200",
      "set /files/etc/services/service-name[port = '9200'] mysqlchk",
      "set /files/etc/services/service-name[port = '9200']/protocol tcp",
    ],
  }

  xinetd::service { 'mysqlchk':
    server     => '/usr/local/bin/clustercheck',
    port       => '9200',
    user       => 'nobody',
    flags      => 'REUSE',
    instances  => 500,
    per_source => 10,
    cps        => '100 1',
  }

  database_user { "${status_user}@localhost":
    ensure        => present,
    password_hash => mysql_password($status_password),
    require       => Class['mariadb::server'],
  }

  mysql_grant { "${status_user}@localhost/*.*":
    user       => "${status_user}@localhost",
    table      => '*.*',
    privileges => [ 'PROCESS' ],
  }

}
