# @summary Install and start the active certificate authority
#
# Installs openvox-server, generates the CA (and this host's certificate)
# with `puppetserver ca setup`, configures the CA, and starts puppetserver.
# Run `bootstrap::install_agents` on the target first.
#
# @param targets The CA host
# @param server
#   The value of `server` in the CA host's `puppet.conf`.  Defaults to the CA
#   host itself.
# @param openvox_collection The collection to install openvox-server from
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf`.  `false` leaves autosigning
#   alone.
# @param dns_alt_names
#   Alternate DNS names for the CA host's own certificate, if it is also a
#   compile master
# @param manage_firewall Open 8140/tcp in firewalld, if firewalld is running
# @param manage_repos
#   Set up the OpenVox package repository (and, for OpenVoxDB, the PostgreSQL
#   repository).  Set this to `false` on hosts that can't reach the internet
#   but already have the packages available, such as from a Satellite.
#
# @return [String] The CA host's certname
plan bootstrap::install_ca (
  TargetSpec                          $targets,
  Optional[String[1]]                 $server             = undef,
  Optional[String[1]]                 $openvox_collection = undef,
  Variant[Boolean, Array[String[1]]]  $autosign           = false,
  Array[String[1]]                    $dns_alt_names      = [],
  Boolean                             $manage_firewall    = false,
  Boolean                             $manage_repos       = true,
) {
  $ca = get_targets($targets)
  if $ca.length != 1 {
    fail_plan("bootstrap::install_ca needs exactly one target (got ${ca.length})")
  }

  run_plan(
    'bootstrap::install_packages',
    'targets'               => $ca,
    'package'               => 'openvox-server',
    'collection'            => $openvox_collection,
    'manage_repos'          => $manage_repos,
    'force_release_package' => false,
  )

  apply_prep($ca)
  $certname = $ca[0].facts['networking']['fqdn']

  run_task(
    'bootstrap::ca_setup',
    $ca,
    "Setting up the CA on ${certname}",
    'certname'      => $certname,
    'dns_alt_names' => $dns_alt_names,
  )

  if $manage_firewall {
    run_plan('bootstrap::open_ports', 'targets' => $ca, 'ports' => [8140])
  }

  apply($ca, '_description' => 'Configuring the CA') {
    class { 'bootstrap::server':
      ca_enabled => true,
      server     => $server,
      ca_server  => $certname,
    }
    class { 'bootstrap::ca':
      autosign => $autosign,
    }
  }

  return $certname
}
