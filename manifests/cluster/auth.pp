class mariadb::cluster::auth (
  $wsrep_sst_password,
  $wsrep_sst_user     = 'root',
) {

  database_user { "${wsrep_sst_user}@localhost":
    ensure        => present,
    password_hash => mysql_password($wsrep_sst_password),
    require       => Class['mariadb::server'],
  }

  mysql_grant { "${wsrep_sst_user}@localhost/*.*":
    user       => "${wsrep_sst_user}@localhost",
    table      => '*.*',
    privileges => [ 'all' ],
    require    => Database_user["${wsrep_sst_user}@localhost"],
  }

}
