`chef-acceptance` helps develop and run acceptance tests from your laptop and from Chef Delivery.

## Why

`chef-acceptance` makes it easy to develop acceptance tests for a project. You can run any type of suites for your project (test-kitchen, pedant, chef provisioning, rspec, etc...) but it enforces a structure so that you can run all of your different acceptance tests in the same way. It also gives you a CLI interface so that you can build your tests without breaking your pipeline until they are ready.

## Setup

Create an `acceptance` directory to your project
```
mkdir acceptance

cd acceptance
```

Generate a test suite
```
chef-acceptance generate my-test-suite
```

Output
```
acceptance
├── my-test-suite
│   ├── .acceptance
│   │   └── acceptance-cookbook
|   |       ├──.chef
|   |       │   └── config.rb
│   │       ├── metadata.rb
│   │       └── recipes
│   │           ├── destroy.rb
│   │           ├── provision.rb
│   │           └── verify.rb
│   └── .gitignore

```

Now you can run your acceptance test phases
```
# chef-acceptance <command> <suite-name> [options]
chef-acceptance provision my-test-suite
chef-acceptance verify my-test-suite
chef-acceptance destroy my-test-suite
```

```
# Run the commands in sequence
chef-acceptance test my-test-suite
```

## Commands

`chef-acceptance provision <suite-name>`
Runs the provision recipe for the given acceptance suite.

`chef-acceptance verify <suite-name>`
Runs the tests for the given acceptance suite.

`chef-acceptance destroy <suite-name>`
Destroy your acceptance setup.

`chef-acceptance test <suite-name>`
Runs the provision, verify, and destroy recipes for the given acceptance suite.

`chef-acceptance generate <suite-name>`
Generates acceptance test suite scaffold that you can modify.

#### Not implemented

Once your acceptance tests are strong you can add this to your build cookbook to run your tests in Chef Delivery:

```
chef_acceptance 'spincycle' do
  acceptance_directory File.join(node['delivery']['project_workspace'], 'acceptance')
  action :provision
end

chef_acceptance 'spincycle' do
  action :verify
end
```

## Example project

```
acceptance
├── lamont-ci
│   ├── .acceptance
│   │   └── acceptance-cookbook
│   │       ├── metadata.rb
│   │       └── recipes
│   │           ├── destroy.rb
│   │           ├── provision.rb
│   │           └── verify.rb
│   ├── .kitchen.yml
│   ├── metadata.rb
│   └── recipes
│       └── default.rb
└── spincycle
    ├── .acceptance
    │   └── acceptance-cookbook
    │       ├── metadata.rb
    │       └── recipes
    │           ├── destroy.rb
    │           ├── provision.rb
    │           └── verify.rb
    ├── .kitchen.yml
    ├── metadata.rb
    └── recipes
        └── default.rb
```

You will notice that in this example, acceptance suites are using Test Kitchen.
But you are not tied to it. You can use any setup you'd like.

## Change Log

The [change log](CHANGELOG.md) for this project follows the principles outlined
from [Keep a CHANGELOG](http://keepachangelog.com/).

## Releasing chef-acceptance

This project uses the [gem-release](https://github.com/svenfuchs/gem-release)
plugin to manage the release process.  Once ready to release `chef-acceptance` from `master` perform the following steps.

1. Verify the "Unreleased" section of the change log is up to date.  The changes will determine the next SemVer release version.
1. Update the change log to reflect the version and date
1. Add the version tag compare link to the footer of the change log even though the tag has not yet been pushed. Follow the pattern.
1. Review and commit changes with comment "vX.Y.Z change log". Push change.
1. Bump version, release to RubyGems and tag version
```
gem bump --version X.Y.Z --tag --release
```
