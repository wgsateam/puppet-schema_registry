# puppet-schema_registry [![Build Status](https://travis-ci.org/miguno/puppet-schema_registry.png?branch=master)](https://travis-ci.org/miguno/puppet-schema_registry)

[Wirbelsturm](https://github.com/miguno/wirbelsturm)-compatible [Puppet](http://puppetlabs.com/) module to deploy
[Confluent schema registry](https://github.com/confluentinc/schema-registry).

You can use this Puppet module to deploy schema registry to physical and virtual machines, for instance via your
existing internal or cloud-based Puppet infrastructure and via a tool such as [Vagrant](http://www.vagrantup.com/)
for local and remote deployments.

---

Table of Contents

* <a href="#quickstart">Quick start</a>
* <a href="#features">Features</a>
* <a href="#requirements">Requirements and assumptions</a>
* <a href="#installation">Installation</a>
* <a href="#configuration">Configuration</a>
* <a href="#usage">Usage</a>
    * <a href="#configuration-examples">Configuration examples</a>
        * <a href="#hiera">Using Hiera</a>
        * <a href="#manifests">Using Puppet manifests</a>
    * <a href="#service-management">Service management</a>
    * <a href="#log-files">Log files</a>
* <a href="#custom-zk-root">Custom ZooKeeper chroot (experimental)</a>
* <a href="#development">Development</a>
* <a href="#todo">TODO</a>
* <a href="#changelog">Change log</a>
* <a href="#contributing">Contributing</a>
* <a href="#Authors">Authors</a>
* <a href="#license">License</a>
* <a href="#references">References</a>

---

<a name="quickstart"></a>

# Quick start

See section [Usage](#usage) below.


<a name="features"></a>

# Features

* Supports [Confluent](http://confluent.io)'s [schema registry](https://github.com/confluentinc/schema-registry) version
  1.0+, i.e. the latest stable release version.
* Supports
  [multi-datacenter deployments](http://confluent.io/docs/current/schema-registry/docs/deployment.html#multi-dc-setup)
  of schema registry.
* Decouples code (Puppet manifests) from configuration data ([Hiera](http://docs.puppetlabs.com/hiera/1/)) through the
  use of Puppet parameterized classes, i.e. class parameters.  Hence you should use Hiera to control how schema registry
  is deployed and to which machines.
* Supports RHEL OS family, e.g. RHEL/CentOS 6, Amazon Linux.
    * Code contributions to support additional OS families are welcome!
* Schema registry is run under process supervision via [supervisord](http://www.supervisord.org/) version 3.0+, using
  [puppet-supervisor](https://github.com/miguno/puppet-supervisor).


<a name="requirements"></a>

# Requirements and assumptions

* **A Kafka cluster running Apache Kafka version 0.8.2+ is required for schema registry.**
  (Earlier versions of Kafka do not work!)
  * Take a look at [puppet-kafka](https://github.com/miguno/puppet-kafka) to deploy such a Kafka cluster for use with
    schema registry.
* The target machines to which you are deploying the schema registry must have the
  **Confluent yum repository configured** so they can retrieve the schema registry package (i.e. RPM).
  See [Confluent Platform: Installation](http://confluent.io/docs/current/installation.html#installation-yum) for
  further information.
    * Because we run schema registry via supervisord through
      [puppet-supervisor](https://github.com/miguno/puppet-supervisor), the supervisord RPM must be available, too.
      See [puppet-supervisor](https://github.com/miguno/puppet-supervisor) for details.
* This module requires that the target machines have a **Java JRE/JDK installed** (e.g. via a separate Puppet module
  such as [puppetlabs-java](https://github.com/puppetlabs/puppetlabs-java)).  You may also want to make sure that the
  Java package is installed _before_ schema registry to prevent startup problems.
    * This module intentionally does not puppet-require Java directly because the approaches how to install "base"
      packages such as Java typically vary across teams and companies.
* This module requires the following **additional Puppet modules**:

    * [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
    * [puppet-supervisor](https://github.com/miguno/puppet-supervisor)

  It is recommended that you add these modules to your Puppet setup via
  [librarian-puppet](https://github.com/rodjek/librarian-puppet).  See the `Puppetfile` snippet in section
  _Installation_ below for a starting example.
* **When using Vagrant**: Depending on your Vagrant box (image) you may need to manually configure/disable firewall
  settings -- otherwise machines may not be able to talk to each other.  One option to manage firewall settings is via
  [puppetlabs-firewall](https://github.com/puppetlabs/puppetlabs-firewall).


<a name="installation"></a>

# Installation

It is recommended to use [librarian-puppet](https://github.com/rodjek/librarian-puppet) to add this module to your
Puppet setup.

Add the following lines to your `Puppetfile`:

```ruby
# Add the stdlib dependency as hosted on public Puppet Forge.
#
# We intentionally do not include the stdlib dependency in our Modulefile to
# make it easier for users who decided to use internal copies of stdlib so
# that their deployments are not coupled to the availability of PuppetForge.
# While there are tools such as puppet-library for hosting internal forges or
# for proxying to the public forge, not everyone is actually using these tools.
mod 'puppetlabs/stdlib', '>= 4.1.0'

# Add the puppet-supervisor module dependency
mod 'supervisor',
  :git => 'https://github.com/miguno/puppet-supervisor.git'

# Add the puppet-schema_registry module
mod 'schema_registry',
  :git => 'https://github.com/miguno/puppet-schema_registry.git'

```

Then use librarian-puppet to install (or update) the Puppet modules.


<a name="configuration"></a>

# Configuration

* See [init.pp](manifests/init.pp) for the list of currently supported configuration parameters.  These should be
  self-explanatory.
* See [params.pp](manifests/params.pp) for the default values of those configuration parameters.

We directly support only two
[configuration settings of schema registry settings](http://confluent.io/docs/current/schema-registry/docs/config.html)
via Puppet class parameters:

* [`port`](http://confluent.io/docs/current/schema-registry/docs/config.html):
  named `$port` in Puppet
* [`kafkastore.connection.url`](http://confluent.io/docs/current/schema-registry/docs/config.html):
  named `$kafkastore_connection_url` in Puppet.  This setting is equivalent to
  [`zookeeper.connect` in Kafka](http://kafka.apache.org/documentation.html#configuration).

All other schema registry settings can be passed via the special Puppet class parameter `$config_map`:
You can use this parameter to "inject" arbitrary config settings via Hiera/YAML into the schema registry configuration
file (default file name: `schema-registry.properties`).  However you should not re-define config settings via
`$config_map` that already have explicit Puppet class parameters (such as `$port` and `$kafkastore_connection_url`).
See the examples below for more information on `$config_map` usage.


<a name="usage"></a>

# Usage

**IMPORTANT: Make sure you read and follow the [Requirements and assumptions](#requirements) section above.**
**Otherwise the examples below will not work.**


<a name="configuration-examples"></a>

## Configuration examples


<a name="hiera"></a>

### Using Hiera


A simple example that deploys schema registry using
[its default settings](http://confluent.io/docs/current/schema-registry/docs/config.html).
It includes the deployment of [supervisord](http://www.supervisord.org/) via
[puppet-supervisor](https://github.com/miguno/puppet-supervisor), which is used to run the schema registry instance
under process supervision.  Here, the schema registry will listen on port `8081/tcp` and will connect to the
ZooKeeper server running at `localhost:2181` (cf.
[`kafkastore.connection.url`](http://confluent.io/docs/current/schema-registry/docs/config.html)).
That's a nice setup for your local development laptop or CI server, for instance.


```yaml
---
classes:
  - schema_registry::service
  - supervisor
```

Below is a more sophisticated example that overrides some of the default settings and also demonstrates the use of
`$config_map`.  In this example, the schema registry connects to the 3-node ZooKeeper ensemble `zookeeper[1-3]`.

```yaml
---
classes:
  - schema_registry::service
  - supervisor

## Confluent schema registry
schema_registry::port: 8888
schema_registry::kafkastore_connection_url:
  - 'zookeeper1:2181'
  - 'zookeeper2:2181'
  - 'zookeeper3:2181'
schema_registry::config_map:
  avro.compatibility.level: 'full'
```


<a name="manifests"></a>

### Using Puppet manifests

_Note: It is recommended to use Hiera to control deployments instead of using this module in your Puppet manifests_
_directly._

TBD


<a name="service-management"></a>

## Service management

To manually start, stop, restart, or check the status of the Confluent schema registry service, respectively:

    $ sudo supervisorctl [start|stop|restart|status] confluent-schema-registry

Example:

    $ sudo supervisorctl status
    confluent-schema-registry             RUNNING    pid 16461, uptime 2 days, 11:22:38


<a name="log-files"></a>

## Log files

* Supervisord log files related to the schema registry processes:
    * `/var/log/supervisor/confluent-schema-registry/confluent-schema-registry.out`
    * `/var/log/supervisor/confluent-schema-registry/confluent-schema-registry.err`
* Supervisord main log file: `/var/log/supervisor/supervisord.log`


<a name="development"></a>

# Development

You should run the `bootstrap` script after a fresh checkout:

    $ ./bootstrap

You have access to a bunch of rake commands to help you with module development and testing:

    $ bundle exec rake -T
    rake acceptance          # Run acceptance tests
    rake build               # Build puppet module package
    rake clean               # Clean a built module package
    rake coverage            # Generate code coverage information
    rake help                # Display the list of available rake tasks
    rake lint                # Check puppet manifests with puppet-lint / Run puppet-lint
    rake module:bump         # Bump module version to the next minor
    rake module:bump_commit  # Bump version and git commit
    rake module:clean        # Runs clean again
    rake module:push         # Push module to the Puppet Forge
    rake module:release      # Release the Puppet module, doing a clean, build, tag, push, bump_commit and git push
    rake module:tag          # Git tag with the current module version
    rake spec                # Run spec tests in a clean fixtures directory
    rake spec_clean          # Clean up the fixtures directory
    rake spec_prep           # Create the fixtures directory
    rake spec_standalone     # Run spec tests on an existing fixtures directory
    rake syntax              # Syntax check Puppet manifests and templates
    rake syntax:hiera        # Syntax check Hiera config files
    rake syntax:manifests    # Syntax check Puppet manifests
    rake syntax:templates    # Syntax check Puppet templates
    rake test                # Run syntax, lint, and spec tests

Of particular interest are:

* `rake test` -- run syntax, lint, and spec tests
* `rake syntax` -- to check you have valid Puppet and Ruby ERB syntax
* `rake lint` -- checks against the [Puppet Style Guide](http://docs.puppetlabs.com/guides/style_guide.html)
* `rake spec` -- run unit tests


<a name="todo"></a>

# TODO

* Is it possible to use a ZK chroot with `kafkastore.connection.url` such as `zookeeper1:2181/mychroot`?
* Enhance in-line documentation of Puppet manifests.
* Add more unit tests and specs.
* Add rollback/remove functionality to completely purge schema registry related packages and configuration files from a machine.


<a name="changelog"></a>

# Change log

See [CHANGELOG](CHANGELOG.md).


<a name="contributing"></a>

# Contributing to this project

Code contributions, bug reports, feature requests etc. are all welcome.

If you are new to GitHub please read [Contributing to a project](https://help.github.com/articles/fork-a-repo) for how
to send patches and pull requests.


<a name="Authors"></a>

# Authors

* [Michael Noll](https://github.com/miguno)


<a name="license"></a>

# License

Copyright © 2015 [VeriSign, Inc.](http://www.verisigninc.com/)

See [LICENSE](LICENSE) for licensing information.


<a name="references"></a>

# References

The test setup of this module was derived from:

* [puppet-module-skeleton](https://github.com/garethr/puppet-module-skeleton)
