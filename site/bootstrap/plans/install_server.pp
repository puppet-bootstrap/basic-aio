# @summary Install and start the OpenVox server
#
# Installs openvox-server, optionally configures autosigning and the
# firewall, and starts the puppetserver service.  Run
# `bootstrap::install_agents` on the server target first.  Installing
# openvox-server may upgrade openvox-agent to satisfy its dependencies.
#
# @param targets The OpenVox server target
# @param openvox_release The major version of OpenVox to install
# @param openvox_collection
#   The collection to install from.  Defaults to `openvox${openvox_release}`
#   when `openvox_release` is set; otherwise the `openvox_bootstrap::install`
#   task picks one.
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf`.  `false` leaves autosigning
#   alone.
# @param dns_alt_names
#   Alternate DNS names for the server's certificate.  These must be set before
#   puppetserver first starts and creates its certificate.
# @param manage_firewall Open the `puppetmaster` service in firewalld, if firewalld is running
plan bootstrap::install_server (
  TargetSpec                          $targets,
  Optional[Integer]                   $openvox_release    = undef,
  Optional[String[1]]                 $openvox_collection = $openvox_release ? {
    undef   => undef,
    default => "openvox${openvox_release}",
  },
  Variant[Boolean, Array[String[1]]]  $autosign           = false,
  Array[String[1]]                    $dns_alt_names      = [],
  Boolean                             $manage_firewall    = false,
) {
  run_task(
    'openvox_bootstrap::install',
    $targets,
    'Installing openvox-server',
    'package'               => 'openvox-server',
    'collection'            => $openvox_collection,
    'force_release_package' => false,
  )

  $puppet_conf = {
    'main'   => $dns_alt_names.empty ? {
      true    => {},
      default => { 'dns_alt_names' => $dns_alt_names.join(',') },
    },
    'server' => $autosign ? {
      true    => { 'autosign' => 'true' },
      default => {},
    },
  }.filter |$section, $settings| { !$settings.empty }

  unless $puppet_conf.empty {
    run_task(
      'openvox_bootstrap::configure',
      $targets,
      'Configuring the server',
      'puppet_conf'            => $puppet_conf,
      'puppet_service_running' => false,
      'puppet_service_enabled' => false,
    )
  }

  if $manage_firewall {
    run_command(
      @(CMD/L),
        if systemctl -q is-active firewalld ; then \
          firewall-cmd -q --permanent --query-service=puppetmaster || \
          { firewall-cmd -q --permanent --add-service=puppetmaster && firewall-cmd -q --reload ; } ; \
        fi
        |-CMD
      $targets,
      'Opening the puppetmaster service in firewalld',
    )
  }

  apply_prep($targets)

  apply($targets, '_description' => 'Starting puppetserver') {
    if $autosign =~ Array {
      file { '/etc/puppetlabs/puppet/autosign.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "${autosign.join("\n")}\n",
        before  => Service['puppetserver'],
      }
    }

    service { 'puppetserver':
      ensure => running,
      enable => true,
    }
  }
}
