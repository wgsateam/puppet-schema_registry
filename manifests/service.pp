# == Class schema_registry::service
#
class schema_registry::service inherits schema_registry {

  if !($schema_registry::service_ensure in ['present', 'absent']) {
    fail('service_ensure parameter must be "present" or "absent"')
  }

  if $schema_registry::service_manage == true {

    supervisor::service { $schema_registry::service_name:
      ensure                 => $schema_registry::service_ensure,
      enable                 => $schema_registry::service_enable,
      command                => $schema_registry::command,
      directory              => '/',
      user                   => $schema_registry::user,
      group                  => $schema_registry::group,
      autorestart            => $schema_registry::service_autorestart,
      startsecs              => $schema_registry::service_startsecs,
      stopwait               => $schema_registry::service_stopsecs,
      retries                => $schema_registry::service_retries,
      stdout_logfile_maxsize => $schema_registry::service_stdout_logfile_maxsize,
      stdout_logfile_keep    => $schema_registry::service_stdout_logfile_keep,
      stderr_logfile_maxsize => $schema_registry::service_stderr_logfile_maxsize,
      stderr_logfile_keep    => $schema_registry::service_stderr_logfile_keep,
      stopsignal             => 'INT',
      stopasgroup            => true,
      require                => Class['::supervisor'],
    }

    if $schema_registry::service_enable == true {
      exec { 'restart-schema-registry':
        command     => "supervisorctl restart ${schema_registry::service_name}",
        path        => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        user        => 'root',
        refreshonly => true,
        subscribe   => File[$config],
        onlyif      => 'which supervisorctl &>/dev/null',
        require     => Class['::supervisor'],
      }
    }

  }

}
