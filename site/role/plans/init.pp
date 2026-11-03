# @summary Build the basic-aio Vagrant environment
#
# Uses the portable plans in the `bootstrap` module to install OpenVox, and
# adds the parts that are specific to this Vagrant environment: the hosts
# file, r10k, and a Choria certificate for the demo user.
#
# @param openvox_release The major version of OpenVox to use
# @param openvox_version
#   The version of openvox-agent to install.  Defaults to the latest version
#   in `openvox_collection`.  Installing openvox-server may upgrade the agent
#   on the server to satisfy openvox-server's dependencies.
# @param openvox_collection The collection to use for openvox-agent
# @param targets The targets to run on
# @param server_target The puppet server target
# @param openvox_server
#   The value of `server` in the agents' `puppet.conf`.  Defaults to the FQDN of
#   `server_target`.  (OpenVox 9 no longer defaults `server` to `puppet`.)
# @param control_repo URL of the control repo
# @param choria_user User name of the demo choria user on the Puppet server
plan role (
  Integer             $openvox_release,
  Optional[String]    $openvox_version    = undef,
  String[1]           $openvox_collection = "openvox${openvox_release}",
  TargetSpec          $targets            = 'all',
  TargetSpec          $server_target      = 'puppet',
  Optional[String[1]] $openvox_server     = undef,
  Variant[
    Stdlib::HTTPUrl,
    Pattern[/\Afile:\/\/\/([^\n\/\0]+(\/)?)+\z/]
  ]                   $control_repo       = 'file:///vagrant/',
  Optional[String]    $choria_user        = 'vagrant',
) {
  run_plan(
    'bootstrap::install_agents',
    'targets'            => $targets,
    'server_target'      => $server_target,
    'openvox_version'    => $openvox_version ? {
      String[1] => $openvox_version,
      default   => undef,
    },
    'openvox_collection' => $openvox_collection,
    'openvox_server'     => $openvox_server,
  )

  # Use the collected facts to build a hash of `host` resources.
  $hosts = get_targets($targets).reduce({}) |$memo, $target| {
    $this_host = {
      $target.facts['networking']['fqdn'] => {
        'ip' => $target.facts['networking']['interfaces'].reduce('') |$m, $v| {
          if $v[0] =~ /^e/ and $v[1]['ip'] {
            $v[1]['ip']
          } else {
            $m
          }
        },
        'host_aliases' => [
          $target.facts['networking']['hostname'],
        ],
      },
    }
    $memo + $this_host
  }

  # Use the hash to configure the hosts file on each target.
  apply($targets, '_description' => 'Configure hosts file') {
    $hosts.each |$key, $value| {
      host { $key:
        * => $value,
      }
    }
  }

  # On the server target, configure r10k.
  apply($server_target, '_description' => 'Configure r10k') {
    class { 'git': }
    -> class { 'r10k':
      remote => $control_repo,
    }
    -> exec { 'r10k deploy environment -pv': # lint:ignore:exec_idempotency
      path => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin',
      # Always run this command to ensure that the environment is deployed.
    }
  }

  # Autosigning and the firewall are left to profile::server, which the
  # server's first agent run applies before any other agent runs.
  run_plan(
    'bootstrap::install_server',
    'targets'            => $server_target,
    'openvox_collection' => $openvox_collection,
  )

  run_plan(
    'bootstrap::first_run',
    'targets'       => $server_target,
    'server_target' => $server_target,
  )

  if $choria_user {
    # Request a choria cert.
    apply(
      $server_target,
      '_description' => 'Request a choria cert',
      '_run_as' => $choria_user,
    ) {
      exec { 'choria enroll':
        environment => [
          "USER=${choria_user}",
          "HOME=/home/${choria_user}",
        ],
        path        => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin',
        creates     => "/home/${choria_user}/.puppetlabs/etc/puppet/ssl/certs/${choria_user}.mcollective.pem",
      }
    }
  }

  # Run the agent on the remaining targets.
  run_plan(
    'bootstrap::first_run',
    'targets'       => get_targets($targets) - get_targets($server_target),
    'server_target' => $server_target,
  )
}
