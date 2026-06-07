class mariadb::repo::debian {
  $os = downcase($facts['os']['name'])

  include ::mariadb
  include ::apt

  # the mariadb_repo_setup script version 2026-04-23 lists these gpg keys:
  # - 0x8167EE24
  # - 0xE3C94F49
  # - 0xcbcb082a1bb943db
  # - 0xf1656f24c74cd1d8
  # - 0x135659e928c12247
  #
  # the keyring that the script downloads has these keys:
  # ./mariadb-keyring-2025.gpg
  # --------------------------
  # pub   rsa4096 2016-03-30 [SC]
  #       177F4010FE56CA3336300305F1656F24C74CD1D8
  # uid           [ unknown] MariaDB Signing Key <signing-key@mariadb.org>
  # sub   rsa4096 2016-03-30 [E]
  #
  # pub   rsa4096 2017-10-16 [SC]
  #       7B963F525AD3AE6259058D30135659E928C12247
  # uid           [ unknown] MariaDB Maxscale <maxscale@googlegroups.com>
  # sub   rsa4096 2017-10-16 [E]
  #
  # pub   rsa2048 2014-12-18 [SC]
  #       4C470FFFEFC4D3DC59778655CE1A3DD5E3C94F49
  # uid           [ unknown] MariaDB Enterprise Signing Key <signing-key@mariadb.com>
  #
  # pub   rsa4096 2025-08-27 [SC]
  #       BB2A36F36C3B4D373BAC328A5D87FACA8C27D14E
  # uid           [ unknown] MariaDB Enterprise Signing Key 2025 <signing-key@mariadb.com>
  # sub   rsa4096 2025-08-27 [E]
  #
  # Since we're only using the regular repo, we've pulled down the keyring,
  # exported 177F4010FE56CA3336300305F1656F24C74CD1D8, added it to the repo,
  # and set up the apt::keyring and apt::source::keyring using it.
  $key_name = 'mariadb-signing-key-20160330.asc'
  $keyring = "/etc/apt/keyrings/${key_name}"
  apt::keyring { $keyring:
    ensure  => present,
    content => file("mariadb/${key_name}"),
  }
  -> apt::source { 'mariadb':
    location => "${::mariadb::mirror}/repo/${::mariadb::version}/${os}",
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
    keyring  => $keyring,
  }
  -> apt::pin { 'apt_mariadb':
    originator => 'mariadb',
    priority   => 1001,
  }

  # for backwards compatibility, we keep the old key (which is in the list
  # of keys above, but not the keyring)
  apt::key { 'mariadb-1':
    id     => '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
    server => 'keyserver.ubuntu.com',
  }

  # and since we've moved this key over to using apt::keyring, we can remove
  # the old apt::key resource; this removes the key from the trusted.gpg
  # keyring - keys in this keyring are unconditionally trusted, so removing
  # this key reduces our overall exposure
  apt::key { 'mariadb-2':
    ensure => absent,
    id     => '177F4010FE56CA3336300305F1656F24C74CD1D8',
  }

  # Note: we don't need to explicitly refer to the apt:source we just defined,
  # because the apt module handles that for us.
  Class['apt::update'] -> Package <| tag == 'mariadb' |>

}
