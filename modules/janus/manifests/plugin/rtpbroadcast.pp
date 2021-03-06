class janus::plugin::rtpbroadcast(
  $minport = 8000,
  $maxport = 9000,
  $source_avg_time = 10,
  $remb_avg_time = 3,
  $switching_delay = 1,
  $session_info_update_time = 10,
  $keyframe_distance_alert = 600,
  $recording_enabled = 'yes',
  $archive_path = '/var/lib/janus/recordings',
  $recording_pattern = 'rec-#{id}-#{time}-#{type}',
  $thumbnailing_pattern = 'thum-#{id}-#{time}-#{type}',
  $thumbnailing_interval = 60,
  $thumbnailing_duration = 10,
  $jobs_path = '/var/lib/janus/jobs',
  $job_pattern = 'job-#{md5}',
  $src_version = undef,
  $rest_url = 'http://127.0.0.1:8088/janus',
) {

  include 'janus'
  require 'apt'

  file { '/etc/janus/janus.plugin.cm.rtpbroadcast.cfg':
    ensure    => 'present',
    content   => template("${module_name}/plugin/rtpbroadcast.cfg"),
    owner     => '0',
    group     => '0',
    mode      => '0644',
    notify    => Service['janus'],
  }

  if $src_version {
    require 'git'
    require 'build::autoconf'
    require 'build::libtool'
    require 'build::dev::libglib2'
    require 'build::dev::libjansson'

    $plugin_repo = 'janus-gateway-rtpbroadcast'

    git::repository { $plugin_repo:
      remote    => "https://github.com/cargomedia/${plugin_repo}.git",
      directory => "/opt/janus/${plugin_repo}",
      revision  => $src_version,
    }
    ~>

    exec { "Install ${name} from Source":
      provider    => shell,
      command     => template("${module_name}/plugin_install.sh"),
      path        => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      refreshonly => true,
      timeout     => 900,
      notify      => Service['janus'],
    }
  } else {
    package { 'janus-gateway-rtpbroadcast':
      provider => 'apt',
      notify   => Service['janus'],
    }
  }

  @bipbip::entry { 'janus-rtpbroadcast':
    plugin  => 'janus-rtpbroadcast',
    options => {
      'url' => $rest_url,
    }
  }

  @bipbip::entry { 'logparser-janus-keyframe-overdue':
    plugin  => 'log-parser',
    options => {
      'metric_group' => 'janus-rtpbroadcast',
      'path' => $janus::log_file,
      'matchers' => [
        { 'name' => 'streams_keyframe_overdue',
          'regexp' => 'Key frame overdue on source' },
      ]
    },
  }
}
