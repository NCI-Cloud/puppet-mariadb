# set up a local haproxy to connect to the mysql cluster
class mariadb::haproxy_client (
  Array[String] $servers,
  Optional[String] $primary = undef,
  Array[String] $listen_options = ['httpchk', 'tcplog', 'logasap'],
  String $log_target = '/dev/log',
  String $log_level = '',
  Boolean $check_state = true,
) {

  class { '::haproxy':
    merge_options    => true,
    global_options   => {
      'log' => "${log_target} local0 ${log_level}"
    },
    defaults_options => {
      'timeout' => [
        'queue 1m',
        'connect 30s',
        'client 8h',
        'client-fin 30s',
        'server 8h',
        'tunnel 8h',
      ],
    }
  }

  haproxy::listen { 'db':
    ipaddress => '*',
    mode      => 'tcp',
    ports     => '3306',
    options   => {
      'log'     => 'global',
      'balance' => 'source', # sticky sessions
      'option'  => $listen_options,
      'timeout' => ['server 8h',
                    'client 8h'],
    },
  }

  if $primary {
    $master = $primary
    $backups = delete($servers, $master)
  } else {
    # no primary has been specified, so instead we randomly pick a server from
    # the list to be the master for this node, and set the rest to be backups
    $index = seeded_rand(length($servers), $::fqdn)
    $master = $servers[$index]
    $backups = delete($servers, $master)
  }

  $check = $check_state ? {
    true  => 'check port 9200',
    false => '',
  }
  $check_backup = $check_state ? {
    true => 'check port 9200 backup',
    false => '',
  }

  haproxy::balancermember { 'db':
    listening_service => 'db',
    ports             => '3306',
    server_names      => $master,
    ipaddresses       => $master,
    options           => $check,
  }

  if $backups {
    haproxy::balancermember { 'db-backups':
      listening_service => 'db',
      ports             => '3306',
      server_names      => $backups,
      ipaddresses       => $backups,
      options           => $check_backup,
    }
  }

}
