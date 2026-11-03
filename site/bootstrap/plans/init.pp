# @summary Bootstrap an OpenVox server infrastructure and agents
#
# Runs `bootstrap::install_infra` to set up the CA, OpenVoxDB, and compile
# masters, then runs the agent on the primary compile master and on every
# other target.  To do something between those steps (deploy code to the
# compile masters, for example), call `bootstrap::install_infra` and
# `bootstrap::first_run` yourself.
#
# By default, everything runs on `server_target`, without OpenVoxDB.
#
# @param targets The agent targets.  The infrastructure hosts are added to them.
# @param server_target The primary compile master
# @param compilers Additional compile masters
# @param ca_targets
#   The CA hosts.  The first is the active CA; any others are standbys.
#   Defaults to `server_target`.
# @param db_targets
#   The OpenVoxDB hosts.  The first one also runs PostgreSQL.  OpenVoxDB isn't
#   installed if this is empty.
# @param db_password Password for the OpenVoxDB PostgreSQL user
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
# @param dns_alt_names Alternate DNS names for the compile masters' certificates
# @param manage_firewall Open the needed ports in firewalld, if firewalld is running
# @param manage_hosts Add every target to every target's hosts file
# @param sign_certs Sign certificate requests for agents whose first run fails
# @param start_service Start and enable the puppet service after the first run
# @param smoke_test
#   If there is more than one compile master, run the agent in no-op mode on
#   every target against each of them
#
# @return [Hash] The topology returned by `bootstrap::install_infra`
plan bootstrap (
  TargetSpec                                         $targets,
  TargetSpec                                         $server_target,
  TargetSpec                                         $compilers          = [],
  Optional[TargetSpec]                               $ca_targets         = undef,
  TargetSpec                                         $db_targets         = [],
  Optional[Variant[String[1], Sensitive[String[1]]]] $db_password        = undef,
  Optional[Integer]                                  $openvox_release    = undef,
  Optional[String[1]]                                $openvox_version    = undef,
  Optional[String[1]]                                $openvox_collection = $openvox_release ? {
    undef   => undef,
    default => "openvox${openvox_release}",
  },
  Optional[String[1]]                                $openvox_server     = undef,
  Variant[Boolean, Array[String[1]]]                 $autosign           = false,
  Array[String[1]]                                   $dns_alt_names      = [],
  Boolean                                            $manage_firewall    = false,
  Boolean                                            $manage_hosts       = false,
  Boolean                                            $sign_certs         = true,
  Boolean                                            $start_service      = true,
  Boolean                                            $smoke_test         = true,
) {
  $database_password = $db_password ? {
    String  => Sensitive($db_password),
    default => $db_password,
  }

  $topology = run_plan(
    'bootstrap::install_infra',
    'targets'            => $targets,
    'server_target'      => $server_target,
    'compilers'          => $compilers,
    'ca_targets'         => $ca_targets,
    'db_targets'         => $db_targets,
    'db_password'        => $database_password,
    'openvox_version'    => $openvox_version,
    'openvox_collection' => $openvox_collection,
    'openvox_server'     => $openvox_server,
    'autosign'           => $autosign,
    'dns_alt_names'      => $dns_alt_names,
    'manage_firewall'    => $manage_firewall,
    'manage_hosts'       => $manage_hosts,
  )

  $ca_target = $ca_targets ? {
    undef   => $server_target,
    default => get_targets($ca_targets)[0],
  }
  $all = get_targets([$targets, $server_target, $compilers, $ca_targets, $db_targets].filter |$spec| { $spec =~ NotUndef })

  run_plan(
    'bootstrap::first_run',
    'targets'       => $all,
    'server_target' => $server_target,
    'ca_target'     => $ca_target,
    'sign_certs'    => $sign_certs,
    'start_service' => $start_service,
  )

  if $smoke_test and $topology['compilers'].length > 1 {
    run_plan('bootstrap::smoke_test', 'targets' => $all, 'servers' => $topology['compilers'])
  }

  return $topology
}
