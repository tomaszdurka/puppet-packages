node default {

  require 'monit'
  require 'gearman'

  exec {'start gearman-job-server':
    command => '/etc/init.d/gearman-job-server start',
    path => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    unless => '/etc/init.d/gearman-job-server status',
  }
}
