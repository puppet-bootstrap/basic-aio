# @summary Install and start OpenVox Server on compile masters
#
# Installs openvox-server, configures the CA service (enabled only on CA
# hosts) and the connection to OpenVoxDB, and starts puppetserver.  Hosts
# without the CA service need signed certificates first (see
# `bootstrap::request_certs`); for the CA host itself, use
# `bootstrap::install_ca` first.
#
# @param targets The compile masters
# @param ca_server The certname of the active CA
# @param server The value of `server` in the compile masters' `puppet.conf`
# @param ca_targets
#   Targets that run the CA service (the active CA and any standbys).  Other
#   targets have the CA service disabled.
# @param openvox_collection The collection to install openvox-server from
# @param puppetdb_urls
#   OpenVoxDB URLs for `puppetdb.conf`.  The compile masters aren't connected
#   to OpenVoxDB if this is empty.
# @param manage_firewall Open 8140/tcp in firewalld, if firewalld is running
# @param manage_repos
#   Set up the OpenVox package repository (and, for OpenVoxDB, the PostgreSQL
#   repository).  Set this to `false` on hosts that can't reach the internet
#   but already have the packages available, such as from a Satellite.
plan bootstrap::install_server (
  TargetSpec          $targets,
  String[1]           $ca_server,
  Optional[String[1]] $server             = undef,
  TargetSpec          $ca_targets         = [],
  Optional[String[1]] $openvox_collection = undef,
  Array[String[1]]    $puppetdb_urls      = [],
  Boolean             $manage_firewall    = false,
  Boolean             $manage_repos       = true,
) {
  $servers = get_targets($targets)
  if $servers.empty {
    return undef
  }
  $ca_names = get_targets($ca_targets).map |$target| { $target.name }

  run_plan(
    'bootstrap::install_packages',
    'targets'               => $servers,
    'package'               => 'openvox-server',
    'collection'            => $openvox_collection,
    'manage_repos'          => $manage_repos,
    'force_release_package' => false,
  )

  if $manage_firewall {
    run_plan('bootstrap::open_ports', 'targets' => $servers, 'ports' => [8140])
  }

  apply_prep($servers)

  parallelize($servers) |$target| {
    $ca_enabled = $target.name in $ca_names
    apply($target, '_description' => 'Configuring OpenVox Server') {
      class { 'bootstrap::server':
        ca_enabled => $ca_enabled,
        server     => $server,
        ca_server  => $ca_server,
      }
      unless $puppetdb_urls.empty {
        class { 'bootstrap::server::puppetdb':
          puppetdb_urls => $puppetdb_urls,
        }
      }
    }
  }
}
