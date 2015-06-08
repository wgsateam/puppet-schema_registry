# == Class schema_registry::install
#
class schema_registry::install inherits schema_registry {

  package { 'confluent-schema-registry':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
