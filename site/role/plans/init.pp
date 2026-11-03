# @summary Build an OpenVox server and attach agents
#
# @param openvox_release The major version of OpenVox to use
# @param openvox_version
#   The version of openvox-agent to install.  Defaults to the latest version
#   in `openvox_collection`.
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
  # We want to specify the OpenVox agent version to install,
  # so we install the agent before calling apply_prep().
  run_task(
    'openvox_bootstrap::install',
    $targets,
    'Installing openvox-agent',
    'collection' => $openvox_collection,
    'version'    => $openvox_version ? {
      String[1] => $openvox_version,
      default   => 'latest',
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

  # OpenVox 9 no longer falls back to `puppet` when `server` is unset,
  # so set it explicitly on every target.
  $server = $openvox_server ? {
    undef   => get_targets($server_target)[0].facts['networking']['fqdn'],
    default => $openvox_server,
  }
  # Leave the puppet service stopped; profile::agent starts it during the
  # first agent run.
  run_task(
    'openvox_bootstrap::configure',
    $targets,
    "Setting server to ${server}",
    'puppet_conf'            => { 'main' => { 'server' => $server } },
    'puppet_service_running' => false,
    'puppet_service_enabled' => false,
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

  # On the server target, install and start the server service.
  apply($server_target, '_description' => 'Install and start server components') {
    include profile::server
  }

  # Run the agent to finish.
  run_command(
    'puppet agent -t -w 30 || { [ $? -eq 2 ] && true; };',
    $server_target,
    'First agent run',
    '_env_vars' => {
      'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin',
    },
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
  run_command(
    'puppet agent -t -w 30 || { [ $? -eq 2 ] && true; };',
    get_targets($targets) - get_targets($server_target),
    'First agent run',
    '_env_vars' => {
      'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin',
    },
  )
}
