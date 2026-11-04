# @summary Connect OpenVox Server to OpenVoxDB
#
# Unlike `openvoxdb::master::config`, this supports several OpenVoxDB
# servers (for failover).  Declare `bootstrap::server` as well.
#
# @param puppetdb_urls
#   OpenVoxDB URLs for `server_urls` in `puppetdb.conf`, such as
#   `https://openvoxdb.example.com:8081`
# @param reports
#   The value of `reports` in `puppet.conf`.  (OpenVox 9 defaults it to
#   `none`.)
#
# @example
#   include bootstrap::server
#   class { 'bootstrap::server::puppetdb':
#     puppetdb_urls => ['https://openvoxdb.example.com:8081'],
#   }
class bootstrap::server::puppetdb (
  Array[Pattern[/\Ahttps:\/\//], 1] $puppetdb_urls,
  String[1]                         $reports = 'store,puppetdb',
) {
  $confdir = '/etc/puppetlabs/puppet'

  package { 'openvoxdb-termini':
    ensure => installed,
    notify => Service['puppetserver'],
  }

  file { "${confdir}/puppetdb.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('bootstrap/puppetdb.conf.epp', { 'puppetdb_urls' => $puppetdb_urls }),
    notify  => Service['puppetserver'],
  }

  file { "${confdir}/routes.yaml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('bootstrap/routes.yaml.epp'),
    notify  => Service['puppetserver'],
  }

  $settings = {
    'storeconfigs'         => 'true',
    'storeconfigs_backend' => 'puppetdb',
    'reports'              => $reports,
  }

  $settings.each |$setting, $value| {
    ini_setting { "puppet.conf server ${setting}":
      ensure  => present,
      path    => "${confdir}/puppet.conf",
      section => 'server',
      setting => $setting,
      value   => $value,
      require => Package['openvoxdb-termini'],
      notify  => Service['puppetserver'],
    }
  }
}
