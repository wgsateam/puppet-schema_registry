# == Class: schema_registry
#
# Deploys an instance of Confluent schema registry.
#
#
# === Parameters
#
# [*config_map*]
#   You can use this parameter to "inject" arbitrary schema registry config settings via Hiera/YAML into the
#   schema registry configuration file. However you should not re-define config settings via `$config_map` that
#   already have explicit Puppet class parameters (such as `kafkastore.connection.url` and `port`).
#   Default: {} (empty hash).
#
# [*kafkastore_connection_url*]
#   Zookeeper url for the Kafka cluster.  A comma-separated list of host:port pairs.
#   Default: 'localhost:2181'.
#
# [*port*]
#   Port to listen on for new connections.
#   Default: 8081.
#
class schema_registry (
  $command             = $schema_registry::params::command,
  $config              = $schema_registry::params::config,
  $config_dir          = $schema_registry::params::config_dir,
  $config_map          = $schema_registry::params::config_map,
  $config_template     = $schema_registry::params::config_template,
  $gid                 = $schema_registry::params::gid,
  $group               = $schema_registry::params::group,
  $group_ensure        = $schema_registry::params::group_ensure,
  $kafkastore_connection_url      = $schema_registry::params::kafkastore_connection_url,
  $logging_config      = $schema_registry::params::logging_config,
  $logging_config_template        = $schema_registry::params::logging_config_template,
  $package_ensure      = $schema_registry::params::package_ensure,
  $package_name        = $schema_registry::params::package_name,
  $port                = $schema_registry::params::port,
  $service_autorestart = hiera('schema_registry::service_autorestart', $schema_registry::params::service_autorestart),
  $service_enable      = hiera('schema_registry::service_enable', $schema_registry::params::service_enable),
  $service_ensure      = $schema_registry::params::service_ensure,
  $service_manage      = hiera('schema_registry::service_manage', $schema_registry::params::service_manage),
  $service_name        = $schema_registry::params::service_name,
  $service_retries     = $schema_registry::params::service_retries,
  $service_startsecs   = $schema_registry::params::service_startsecs,
  $service_stderr_logfile_keep    = $schema_registry::params::service_stderr_logfile_keep,
  $service_stderr_logfile_maxsize = $schema_registry::params::service_stderr_logfile_maxsize,
  $service_stdout_logfile_keep    = $schema_registry::params::service_stdout_logfile_keep,
  $service_stdout_logfile_maxsize = $schema_registry::params::service_stdout_logfile_maxsize,
  $service_stopsecs    = $schema_registry::params::service_stopsecs,
  $shell               = $schema_registry::params::shell,
  $uid                 = $schema_registry::params::uid,
  $user                = $schema_registry::params::user,
  $user_description    = $schema_registry::params::user_description,
  $user_ensure         = $schema_registry::params::user_ensure,
  $user_home           = $schema_registry::params::user_home,
  $user_manage         = hiera('schema_registry::user_manage', $schema_registry::params::user_manage),
  $user_managehome     = hiera('schema_registry::user_managehome', $schema_registry::params::user_managehome),
) inherits schema_registry::params {

  validate_string($command)
  validate_absolute_path($config)
  validate_absolute_path($config_dir)
  validate_hash($config_map)
  validate_string($config_template)
  if !is_integer($gid) { fail('The $gid parameter must be an integer number') }
  validate_string($group)
  validate_string($group_ensure)
  validate_array($kafkastore_connection_url)
  validate_absolute_path($logging_config)
  validate_string($logging_config_template)
  validate_string($package_ensure)
  validate_string($package_name)
  if !is_integer($port) { fail('The $port parameter must be an integer number') }
  validate_bool($service_autorestart)
  validate_bool($service_enable)
  validate_string($service_ensure)
  validate_bool($service_manage)
  validate_string($service_name)
  if !is_integer($service_retries) { fail('The $service_retries parameter must be an integer number') }
  if !is_integer($service_startsecs) { fail('The $service_startsecs parameter must be an integer number') }
  if !is_integer($service_stderr_logfile_keep) {
    fail('The $service_stderr_logfile_keep parameter must be an integer number')
  }
  validate_string($service_stderr_logfile_maxsize)
  if !is_integer($service_stdout_logfile_keep) {
    fail('The $service_stdout_logfile_keep parameter must be an integer number')
  }
  validate_string($service_stdout_logfile_maxsize)
  if !is_integer($service_stopsecs) { fail('The $service_stopsecs parameter must be an integer number') }
  validate_absolute_path($shell)
  if !is_integer($uid) { fail('The $uid parameter must be an integer number') }
  validate_string($user)
  validate_string($user_description)
  validate_string($user_ensure)
  validate_absolute_path($user_home)
  validate_bool($user_manage)
  validate_bool($user_managehome)

  include '::schema_registry::users'
  include '::schema_registry::install'
  include '::schema_registry::config'
  include '::schema_registry::service'

  # Anchor this as per #8040 - this ensures that classes won't float off and
  # mess everything up. You can read about this at:
  # http://docs.puppetlabs.com/puppet/2.7/reference/lang_containment.html#known-issues
  anchor { 'schema_registry::begin': }
  anchor { 'schema_registry::end': }

  Anchor['schema_registry::begin']
  -> Class['::schema_registry::users']
  -> Class['::schema_registry::install']
  -> Class['::schema_registry::config']
  ~> Class['::schema_registry::service']
  -> Anchor['schema_registry::end']
}
