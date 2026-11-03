# @summary Configure OpenVox Server on a compile master or CA host
#
# The `bootstrap` plans apply this class with Bolt, and a control repo can
# include it to keep managing the same settings afterward.
#
# @param ca_enabled
#   Run the CA service on this host.  Disable it on compile masters that use
#   a CA on another host, before puppetserver first starts; otherwise it
#   generates its own CA.
# @param server The value of `server` in `puppet.conf`.  Not managed if unset.
# @param ca_server The value of `ca_server` in `puppet.conf`.  Not managed if unset.
# @param crl_refresh_interval
#   How often a host without the CA service refreshes the CRL from the CA.
# @param reload_on_crl_change
#   On hosts without the CA service, reload puppetserver whenever the CRL
#   changes, so that revocations take effect without a manual reload.
# @param package_ensure The `ensure` value for the openvox-server package
#
# @example
#   class { 'bootstrap::server':
#     ca_enabled => false,
#     ca_server  => 'ca.example.com',
#   }
class bootstrap::server (
  Boolean             $ca_enabled           = true,
  Optional[String[1]] $server               = undef,
  Optional[String[1]] $ca_server            = undef,
  String[1]           $crl_refresh_interval = '1h',
  Boolean             $reload_on_crl_change = true,
  String[1]           $package_ensure       = 'installed',
) {
  $puppet_conf = '/etc/puppetlabs/puppet/puppet.conf'

  package { 'openvox-server':
    ensure => $package_ensure,
  }

  file { '/etc/puppetlabs/puppetserver/services.d/ca.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('bootstrap/ca.cfg.epp', { 'ca_enabled' => $ca_enabled }),
    require => Package['openvox-server'],
    notify  => Service['puppetserver'],
  }

  $settings = {
    'server'               => $server,
    'ca_server'            => $ca_server,
    'crl_refresh_interval' => $ca_enabled ? {
      true    => undef,
      default => $crl_refresh_interval,
    },
  }.filter |$setting, $value| { $value =~ NotUndef }

  $settings.each |$setting, $value| {
    ini_setting { "puppet.conf main ${setting}":
      ensure  => present,
      path    => $puppet_conf,
      section => 'main',
      setting => $setting,
      value   => $value,
      notify  => Service['puppetserver'],
    }
  }

  $reload_ensure = (!$ca_enabled and $reload_on_crl_change) ? {
    true    => 'file',
    default => 'absent',
  }

  file { '/etc/systemd/system/openvox-crl-reload.service':
    ensure  => $reload_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('bootstrap/openvox-crl-reload.service.epp'),
    notify  => Exec['bootstrap::server systemctl daemon-reload'],
  }

  file { '/etc/systemd/system/openvox-crl-reload.path':
    ensure  => $reload_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('bootstrap/openvox-crl-reload.path.epp', { 'hostcrl' => '/etc/puppetlabs/puppet/ssl/crl.pem' }),
    notify  => Exec['bootstrap::server systemctl daemon-reload'],
  }

  exec { 'bootstrap::server systemctl daemon-reload':
    command     => 'systemctl daemon-reload',
    path        => ['/usr/bin', '/bin'],
    refreshonly => true,
  }

  if $reload_ensure == 'file' {
    service { 'openvox-crl-reload.path':
      ensure    => running,
      enable    => true,
      subscribe => Exec['bootstrap::server systemctl daemon-reload'],
    }
  } else {
    # Stop and disable the watcher before its unit files are removed, in case
    # this host had it before.
    service { 'openvox-crl-reload.path':
      ensure => stopped,
      enable => false,
      before => [
        File['/etc/systemd/system/openvox-crl-reload.path'],
        File['/etc/systemd/system/openvox-crl-reload.service'],
      ],
    }
  }

  service { 'puppetserver':
    ensure => running,
    enable => true,
  }
}
