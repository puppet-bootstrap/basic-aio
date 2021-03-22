# @summary Build a Puppet server and attach agents
# @param puppet_release The major version of Puppet to use
# @param puppet_version The version of puppet-agent to install
# @param targets The targets to run on
# @param puppet_target The puppet server target
# @param control_repo URL of the control repo
# @param choria_user User name of the demo choria user on the Puppet server
plan role (
  Integer          $puppet_release,
  Optional[String] $puppet_version = undef,
  TargetSpec       $targets        = 'all',
  TargetSpec       $puppet_target  = 'puppet',
  Variant[
    Stdlib::HTTPUrl,
    Pattern[/\Afile:\/\/\/([^\n\/\0]+(\/)?)+\z/]
  ]                $control_repo   = 'file:///vagrant/',
  Optional[String] $choria_user    = 'vagrant',
) {
  # We want to specify the Puppet agent version to install,
  # so we start by running the puppet_agent::install task.
  $puppet_collection = "puppet${puppet_release}"
  $agent_install_message = $puppet_version ? {
    /^.+$/  => "Installing puppet-agent ${puppet_version}",
    default => "Installing ${puppet_collection}",
  }
  $agent_version = $puppet_version ? {
    /^.+$/  => { 'version' => $puppet_version },
    default => {},
  }
  $agent_install_args = {
    'collection' => $puppet_collection,
  } + $agent_version
  run_task('puppet_agent::install', $targets, $agent_install_message, $agent_install_args)

  # apply_prep will see that puppet-agent is already
  # installed and collect facts.
  apply_prep($targets)

  # Use the collected facts to build a hash of `host` resources.
  $hosts = get_targets($targets).reduce({}) |$memo, $target| {
    $this_host = {
      $target.facts['fqdn'] => {
        'ip' => $target.facts['networking']['interfaces'].reduce('') |$m, $v| {
          if $v[0] =~ /^e/ and $v[1]['ip'] {
            $v[1]['ip']
          } else {
            $m
          }
        },
        'host_aliases' => [
          $target.facts['hostname'],
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

  # On the puppet server target, configure r10k.
  apply($puppet_target, '_description' => 'Configure r10k') {
    class { 'git': }
    -> class { 'r10k':
      remote => $control_repo,
    }
    -> exec { 'r10k deploy environment -pv':
      path    => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin',
      creates => '/etc/puppetlabs/code/environments/production/Puppetfile',
    }
  }

  # On the puppet server target, install and start the puppetserver.
  apply($puppet_target, '_description' => 'Install and start server components') {
    include profile::puppetserver
  }

  # Run the puppet agent to finish.
  run_command(
    'puppet agent -t -w 30 || { [ $? -eq 2 ] && true; };',
    $puppet_target,
    'First Puppet agent run',
    '_env_vars' => {
      'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin',
    },
  )

  if $choria_user {
    # Request a choria cert.
    run_command(
      'choria enroll',
      $puppet_target,
      'Request a choria cert',
      '_run_as' => $choria_user,
    )
  }

  # Run the puppet agent on the remaining targets.
  run_command(
    'puppet agent -t -w 30 || { [ $? -eq 2 ] && true; };',
    get_targets($targets) - get_targets($puppet_target),
    'First Puppet agent run',
    '_env_vars' => {
      'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin',
    },
  )
}
