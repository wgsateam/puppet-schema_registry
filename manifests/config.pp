# == Class schema_registry::config
#
class schema_registry::config inherits schema_registry {

  file { $config:
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($schema_registry::config_template),
  }

  file { $logging_config:
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($schema_registry::logging_config_template),
  }

}
