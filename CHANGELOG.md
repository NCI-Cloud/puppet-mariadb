# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project (tries to) adhere to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

