node default {

  include 'fluentd'
  ## source from journal via including systemd journald customization
  include 'systemd::config::journald'


  # Dump everything  for test verification

  $output_config = @(END)
<match **>
  @type copy
  <store>
    @type file
    path /tmp/dump
    format json
  </store>
</match>
  | END

  fluentd::config { 'dump_to_file':
    priority => 85,
    content  => inline_template($output_config),
  }

  exec { 'log error foo':
    provider => shell,
    command  => 'logger -p local0.error foo',
    path     => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    require  => Service['fluentd'],
  } ->
  # see http://docs.fluentd.org/v0.12/articles/signals#sigusr1
  exec { 'flush fluentd':
    provider => shell,
    command  => 'pkill -SIGUSR1 fluentd',
    path     => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    require  => Service['fluentd'],
  }
}
