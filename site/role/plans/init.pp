# @summary Build an OpenVox server and attach agents
#
# @param openvox_release The major version of OpenVox to use
# @param openvox_version The version of openvox-agent to install
# @param openvox_collection The collection to use for openvox-agent
# @param release_package The URL of the openvox-release package
# @param openvox_agent The name of the openvox-agent package
# @param targets The targets to run on
# @param server_target The puppet server target
# @param control_repo URL of the control repo
# @param choria_user User name of the demo choria user on the Puppet server
plan role (
  Integer          $openvox_release,
  Optional[String] $openvox_version    = undef,
  String[1]        $openvox_collection = "openvox${openvox_release}",
  String[1]        $release_package    = "https://yum.voxpupuli.org/${openvox_collection}-release-el-\$( rpm --eval '%{rhel}' ).noarch.rpm",
  String[1]        $openvox_agent      = 'openvox-agent',
  TargetSpec       $targets            = 'all',
  TargetSpec       $server_target      = 'puppet',
  Variant[
    Stdlib::HTTPUrl,
    Pattern[/\Afile:\/\/\/([^\n\/\0]+(\/)?)+\z/]
  ]                $control_repo       = 'file:///vagrant/',
  Optional[String] $choria_user        = 'vagrant',
) {
  # We want to specify the OpenVox agent version to install,
  # so we start by manually installing the agent package.
  run_command("dnf -y install ${release_package}", $targets, 'Installing openvox-release package')

  if $openvox_version =~ String[1] {
    run_command("dnf -y install ${openvox_agent}-${openvox_version}", $targets, "Installing openvox-agent package version ${openvox_version}")
  } else {
    run_command("dnf -y install ${openvox_agent}", $targets, 'Installing openvox-agent package')
  }

  get_targets($targets).each |$target| {
    # Set the puppet-agent feature to true so that
    # apply_prep() will not attempt to install the agent.
    set_feature($target, 'puppet-agent', true)
  }

  # apply_prep will see that puppet-agent is already
  # installed and collect facts.
  apply_prep($targets)

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
    -> exec { 'r10k deploy environment -pv':
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
