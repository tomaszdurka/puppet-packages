class puppet::db(
  $port,
  $port_ssl
) {

  include 'puppet::common'
  include 'puppet::master'

  $path_ssl_private = '/etc/puppetdb/ssl/private.pem'
  $path_ssl_public = '/etc/puppetdb/ssl/public.pem'
  $path_ssl_ca = '/etc/puppetdb/ssl/ca.pem'

  Exec {
    path => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  }

  file { '/etc/default/puppetdb':
    ensure  => file,
    content => template("${module_name}/db/default"),
    group   => '0',
    owner   => '0',
    mode    => '0644',
    notify  => Service['puppetdb'],
  }
  ->

  package { 'puppetdb':
    ensure  => present,
    require => Helper::Script['install puppet apt sources'],
  }
  ->

  file { '/etc/puppetdb/ssl':
    ensure => directory,
    owner  => 'puppetdb',
    group  => 'puppetdb',
    mode   => '0700',
  }
  ->

  exec { $path_ssl_private:
    command => "cp $(puppet master --configprint hostprivkey) ${path_ssl_private} && chown puppetdb:puppetdb ${path_ssl_private} && chmod 600 ${path_ssl_private}",
    creates => $path_ssl_private,
    require => Package['puppetmaster'],
  }
  ->

  exec { $path_ssl_public:
    command => "cp $(puppet master --configprint hostcert) ${path_ssl_public} && chown puppetdb:puppetdb ${path_ssl_public} && chmod 600 ${path_ssl_public}",
    creates => $path_ssl_public,
    require => Package['puppetmaster'],
  }
  ->

  exec { $path_ssl_ca:
    command => "cp $(puppet master --configprint localcacert) ${path_ssl_ca} && chown puppetdb:puppetdb ${path_ssl_ca} && chmod 600 ${path_ssl_ca}",
    creates => $path_ssl_ca,
    require => Package['puppetmaster'],
  }
  ->

  file { '/etc/puppetdb/conf.d':
    ensure => directory,
    owner  => 'puppetdb',
    group  => 'puppetdb',
    mode   => '0640',
  }

  file { '/etc/puppetdb/conf.d/config.ini':
    ensure  => file,
    content => template("${module_name}/db/config.ini"),
    owner   => 'puppetdb',
    group   => 'puppetdb',
    mode    => '0640',
    notify  => Service['puppetdb'],
  }

  file { '/etc/puppetdb/conf.d/jetty.ini':
    ensure  => file,
    content => template("${module_name}/db/jetty.ini"),
    owner   => 'puppetdb',
    group   => 'puppetdb',
    mode    => '0640',
    notify  => Service['puppetdb'],
  }

  service { 'puppetdb':
    enable => true,
  }
  ~>

  exec { 'puppet::db ready' :
    command     => 'timeout --signal=9 120 bash -c \'while ! (netstat -altp | grep -w "$(cat /var/run/puppetdb.pid)"); do sleep 0.5; done\'',
    path        => '/usr/bin:/bin',
    refreshonly => true,
  }

  @monit::entry { 'puppetdb':
    content => template("${module_name}/db/monit"),
    require => Exec['puppet::db ready'],
  }
}
