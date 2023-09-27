# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project (tries to) adhere to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Minor tweaks to the Debian package installation.

## [1.3.3] - 2022-10-15
### Changed
- Moved from sks-keyservers.net to keyserver.ubuntu.com, as sks-keyservers.net
  is no longer available.

## [1.3.2] - 2022-10-05
### Fixed
- Stupid typos that broke catalogue build for any clustered
  configuration.
- Galera requires binlog_format=ROW - this was changed to
  MIXED due to misreading of MariaDB 10.6 series release notes.

### Added
- puppet-syntax checks to the Rakefile . . .

## [1.3.1] - 2022-10-05 [YANKED]
### Fixed
- Better handling of replication support packages. In particular,
  don't try to install percona-xtrabackup in concert with Mariadb
  10.3 or greater, as this is not a supported configuration.
- Fix issue with the check scripts being unable to connect to the
  local server. This was a result of the scripts specifying the
  `--port=` option on the mysql command line, which as of MariaDB
  10.6.1 forces the use of a TCP connection even when
  `--host=localhost` is specified. Please see discussion at
  https://jira.mariadb.org/browse/MDEV-14974 for more detail.

## [1.3.0] - 2022-09-29
### Fixed
- Clean up of galera configuration.

### Added
- Add support for installing and configuring MariaDB 10.6. This is
  the current LTS version, supported until 2026.

### Deprecated
- Deprecate use of the mariadb::cluster::config class

## [1.2.9] - 2021-08-04
### Fixed
- Fix the creation of the wsrep_sst_user - this should be @localhost,
  not @%, if only to minimise the potential attack surface.

## [1.2.8] - 2021-08-03
### Added
- Add an haproxy_client class to create a local haproxy instance to
  mediate access to the cluster, allowing high availability for clients
  with no extra local smarts.
- Create a meaningful clustercheck script for standalone mode, so that
  clients using haproxy to access the "cluster" will still see the
  standalone node as up.

  This is necessary to support temporarily breaking a cluster down to
  a single standalone node in case of clustering issues.

## [1.2.7] - 2021-04-08
### Fixed
- Fix broken backwards compatibility for 10.5 nodes which have been
  upgraded. Previously we hard-coded the assumption that root would
  always use unix_socket auth, but for nodes which have been upgraded
  from a previous version root will still be using password auth. This
  leads to things breaking when we move debian.cnf over to using root
  rather than debian-sys-maint.

### Changed
- Minor syntax/lint fixes

## [1.2.6] - 2021-04-08 [YANKED]
### Added
- This CHANGELOG file
- 10.5 and later specific debian.cnf
- Allow standalone mode to correctly disable galera clustering

### Deprecated
- Use of debiansysmaint_password for 10.5 or later

## [1.2.5] - 2021-03-31
### Fixed
- Added back missing my.cnf template parameters

## [1.2.4] - 2021-03-31
### Fixed
- Fix typo in mysqlbackup.sh script

