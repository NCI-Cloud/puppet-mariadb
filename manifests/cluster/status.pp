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
    'cluster':    { $clustercheck = 'mariadb/clustercheck.epp' }
    'standalone': { $clustercheck = 'mariadb/clustercheck-standalone.epp' }
    default: {}
  }

  # the operational version does the proper checks, the maintenance version
  # always says no, go away
  $clustercheck_epp_params = {
    status_user => $status_user,
    status_password => $status_password,
  }
  file { '/usr/local/bin/clustercheck-operational':
    content => epp($clustercheck, $clustercheck_epp_params),
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

  # when doing maintenance, stop puppet and adjust this link to point at the
  # maintenance script
  file { '/usr/local/bin/clustercheck':
    ensure => link,
    target => '/usr/local/bin/clustercheck-operational',
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
    privileges => [ 'USAGE' ],
  }

}
