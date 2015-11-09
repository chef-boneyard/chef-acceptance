# Change Log
This change log follows the principles
outlined from [Keep a CHANGELOG](http://keepachangelog.com/).

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Changed
- Refactored TestSuite Struct to a class
- Test command aggregates recipes into a single run list

### Removed
- Removed mixlib-shellout dependency from gem

## [0.1.0] - 2015-10-28
### Added
- `chef-acceptance` executable
- `provision`, `verify`, `destroy`, `test`, `generate` commands
- utility commands
- Travis CI support

[Unreleased]: https://github.com/chef/chef-acceptance/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/chef/chef-acceptance/compare/3b46b84532f734f07b2cca5e4c57d34ec535f0d7...v0.1.0
