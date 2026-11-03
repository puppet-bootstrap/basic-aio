# @summary Install and configure the OpenVox agent
#
# Installs openvox-agent, collects facts, and sets `server` in `puppet.conf`.
# The puppet service is left stopped so that it doesn't race the first agent
# run; `bootstrap::first_run` starts it.
#
# @param targets The targets to install the agent on
# @param server_target
#   The OpenVox server target.  Used to find the default value of `openvox_server`.
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
#   `server_target`.  (OpenVox 9 no longer defaults `server` to `puppet`.)
# @param ca_target
#   The CA target, if the CA isn't on `server_target`.  Used to find the
#   default value of `openvox_ca_server`.
# @param openvox_ca_server
#   The value of `ca_server` in `puppet.conf`.  Defaults to the FQDN of
#   `ca_target`, or isn't set if neither is set.
#
# @return [String] The value of `server` set on the targets
plan bootstrap::install_agents (
  TargetSpec            $targets,
  Optional[TargetSpec]  $server_target      = undef,
  Optional[Integer]     $openvox_release    = undef,
  Optional[String[1]]   $openvox_version    = undef,
  Optional[String[1]]   $openvox_collection = $openvox_release ? {
    undef   => undef,
    default => "openvox${openvox_release}",
  },
  Optional[String[1]]   $openvox_server     = undef,
  Optional[TargetSpec]  $ca_target          = undef,
  Optional[String[1]]   $openvox_ca_server  = undef,
) {
  if $openvox_server =~ Undef and $server_target =~ Undef {
    fail_plan('Either openvox_server or server_target must be set')
  }

  # We want to choose the OpenVox agent version to install,
  # so we install the agent before calling apply_prep().
  run_task(
    'openvox_bootstrap::install',
    $targets,
    'Installing openvox-agent',
    'collection' => $openvox_collection,
    'version'    => $openvox_version ? {
      undef   => 'latest',
      default => $openvox_version,
    },
  )

  get_targets($targets).each |$target| {
    # Set the puppet-agent feature to true so that
    # apply_prep() will not attempt to install the agent.
    set_feature($target, 'puppet-agent', true)
  }

  # apply_prep will see that puppet-agent is already
  # installed and collect facts.
  apply_prep($targets)

  if $openvox_server =~ String {
    $server = $openvox_server
  } else {
    $server_ref = get_targets($server_target)[0]
    # apply_prep() already collected facts if the server is one of the targets.
    unless $server_ref.facts['networking'] {
      run_plan('facts', 'targets' => $server_ref)
    }
    $server = $server_ref.facts['networking']['fqdn']
  }

  if $openvox_ca_server =~ String {
    $ca_server = $openvox_ca_server
  } elsif $ca_target =~ NotUndef {
    $ca_ref = get_targets($ca_target)[0]
    unless $ca_ref.facts['networking'] {
      run_plan('facts', 'targets' => $ca_ref)
    }
    $ca_server = $ca_ref.facts['networking']['fqdn']
  } else {
    $ca_server = undef
  }

  $settings = $ca_server ? {
    undef   => { 'server' => $server },
    default => { 'server' => $server, 'ca_server' => $ca_server },
  }

  run_task(
    'openvox_bootstrap::configure',
    $targets,
    "Setting server to ${server}",
    'puppet_conf'            => { 'main' => $settings },
    'puppet_service_running' => false,
    'puppet_service_enabled' => false,
  )

  return $server
}
