# Change Log
This change log follows the principles
outlined from [Keep a CHANGELOG](http://keepachangelog.com/).

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- `node['chef-acceptance']['suite-dir']` attribute available in acceptance cookbook recipes
- Test results summary displayed at end of run

### Fixed
- `test` command returns non-zero exit code when an error is encountered

### Changed
- `config.rb` is generated automatically
- Improved error handling when running test suites

## [0.2.0] - 2015-11-17
### Changed
- `test` command `--destroy` option changed to a boolean as `--skip-destroy`
- Relax all development dependency versions

## [0.1.0] - 2015-10-28
### Added
- `chef-acceptance` executable
- `provision`, `verify`, `destroy`, `test`, `generate` commands
- utility commands
- Travis CI support

[Unreleased]: https://github.com/chef/chef-acceptance/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/chef/chef-acceptance/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/chef/chef-acceptance/compare/3b46b84532f734f07b2cca5e4c57d34ec535f0d7...v0.1.0
