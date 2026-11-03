# @summary Bootstrap an OpenVox server and agents
#
# Installs the agent everywhere, installs and starts the server, and then
# runs the agent on the server and the remaining targets.  To do something
# between those steps (deploy code to the server, for example), call
# `bootstrap::install_agents`, `bootstrap::install_server`, and
# `bootstrap::first_run` yourself.
#
# @param targets The targets to bootstrap, including the server
# @param server_target The target to install the OpenVox server on
# @param openvox_release The major version of OpenVox to install
# @param openvox_version
#   The version of openvox-agent to install.  Defaults to the latest version
#   in `openvox_collection`.  Installing openvox-server may upgrade the agent
#   on the server to satisfy openvox-server's dependencies.
# @param openvox_collection
#   The collection to install from.  Defaults to `openvox${openvox_release}`
#   when `openvox_release` is set; otherwise the `openvox_bootstrap::install`
#   task picks one.
# @param openvox_server
#   The value of `server` in `puppet.conf`.  Defaults to the FQDN of
#   `server_target`.
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf`.  `false` leaves autosigning
#   alone.
# @param dns_alt_names Alternate DNS names for the server's certificate
# @param manage_firewall Open the `puppetmaster` service in firewalld, if firewalld is running
# @param sign_certs Sign certificate requests for agents whose first run fails
# @param start_service Start and enable the puppet service after the first run
plan bootstrap (
  TargetSpec                          $targets,
  TargetSpec                          $server_target,
  Optional[Integer]                   $openvox_release    = undef,
  Optional[String[1]]                 $openvox_version    = undef,
  Optional[String[1]]                 $openvox_collection = $openvox_release ? {
    undef   => undef,
    default => "openvox${openvox_release}",
  },
  Optional[String[1]]                 $openvox_server     = undef,
  Variant[Boolean, Array[String[1]]]  $autosign           = false,
  Array[String[1]]                    $dns_alt_names      = [],
  Boolean                             $manage_firewall    = false,
  Boolean                             $sign_certs         = true,
  Boolean                             $start_service      = true,
) {
  run_plan(
    'bootstrap::install_agents',
    'targets'            => get_targets([$targets, $server_target]),
    'server_target'      => $server_target,
    'openvox_version'    => $openvox_version,
    'openvox_collection' => $openvox_collection,
    'openvox_server'     => $openvox_server,
  )

  run_plan(
    'bootstrap::install_server',
    'targets'            => $server_target,
    'openvox_collection' => $openvox_collection,
    'autosign'           => $autosign,
    'dns_alt_names'      => $dns_alt_names,
    'manage_firewall'    => $manage_firewall,
  )

  run_plan(
    'bootstrap::first_run',
    'targets'       => get_targets([$targets, $server_target]),
    'server_target' => $server_target,
    'sign_certs'    => $sign_certs,
    'start_service' => $start_service,
  )
}
