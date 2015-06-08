# == Class schema_registry::params
#
class schema_registry::params {
  $config_dir          = '/etc/schema-registry'
  $config              = "${config_dir}/schema-registry.properties"
  $config_map          = {}
  $config_template     = "${module_name}/schema-registry.properties.erb"
  $command             = "/usr/bin/schema-registry-start ${config}"
  $gid                 = 55001
  $group               = 'schema-registry'
  $group_ensure        = 'present'
  $kafkastore_connection_url      = ['localhost:2181']
  $logging_config      = "${config_dir}/log4j.properties"
  $logging_config_template        = "${module_name}/log4j.properties.erb"
  $package_ensure      = 'present'
  $package_name        = 'confluent-schema-registry'
  $port                = 8081
  $service_autorestart = true
  $service_enable      = true
  $service_ensure      = 'present'
  $service_manage      = true
  $service_name        = 'confluent-schema-registry'
  $service_retries     = 999
  $service_startsecs   = 10
  $service_stderr_logfile_keep    = 10
  $service_stderr_logfile_maxsize = '20MB'
  $service_stdout_logfile_keep    = 5
  $service_stdout_logfile_maxsize = '20MB'
  $service_stopsecs    = 120
  $shell               = '/bin/bash'
  $uid                 = 55001
  $user                = 'schema-registry'
  $user_description    = 'Confluent schema registry system account'
  $user_ensure         = 'present'
  $user_home           = "/home/${user}"
  $user_manage         = true
  $user_managehome     = true

  case $::osfamily {
    'RedHat': {}

    default: {
      fail("The ${module_name} module is not supported on a ${::osfamily} based system.")
    }
  }
}
