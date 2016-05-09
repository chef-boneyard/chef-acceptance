# CHANGELOG

We strongly recommend following `master` branch for chef-acceptance.

## [master]
- `--data-path` option to core commands which can be used to override the directory in which temporary chef files and log files will be created.
- `--timeout=N` option to configure timeout for chef-client
- `--audit-mode` and `--no-audit-mode` options set audit_mode in the config.rb to :enabled or :disabled, respectively.
- `node['chef-acceptance']['suite-dir']` attribute available in acceptance cookbook recipes
- Exit code is set properly based on test failures.
- Test results summary displayed at end of run
- Multiple test suite can be run by using a regex
- Not specifying any suites will run all available suites
- Run Chef under a clean bundler environment.
- Improved error handling when running test suites

## [0.2.0]
- `test` command `--destroy` option changed to a boolean as `--skip-destroy`
- Relax all development dependency versions

## [0.1.0]
- `chef-acceptance` executable
- `provision`, `verify`, `destroy`, `test`, `generate` commands
- utility commands
- Travis CI support
