# @summary Bootstrap an OpenVox server and agents
#
# Uses the plans in the `bootstrap` module to install OpenVox on
# `server_target` and `targets`, optionally deploying a control repo to the
# server with r10k before the first agent run.
#
# `vagrant up` runs this plan with `manage_hosts`, `control_repo`, and
# `choria_user` set for the demo environment.
#
# @param targets The agent targets.  May include `server_target`.
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
#   `server_target`.  (OpenVox 9 no longer defaults `server` to `puppet`.)
# @param control_repo
#   URL of a control repo to deploy to the server with r10k before the first
#   agent run.  No code is deployed if this isn't set.
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf`.  `false` leaves autosigning
#   alone.
# @param dns_alt_names Alternate DNS names for the server's certificate
# @param manage_firewall Open the `puppetmaster` service in firewalld, if firewalld is running
# @param sign_certs Sign certificate requests for agents whose first run fails
# @param manage_hosts
#   Add every target to every target's hosts file, using the facts collected
#   from them.  Useful when the targets can't resolve each other's names.
# @param choria_user
#   If set, request a Choria certificate for this user on the server after
#   the server's first agent run.  The control repo must set up Choria.
plan basic_aio (
  TargetSpec                          $targets,
  TargetSpec                          $server_target,
  Optional[Integer]                   $openvox_release    = undef,
  Optional[String]                    $openvox_version    = undef,
  Optional[String[1]]                 $openvox_collection = $openvox_release ? {
    undef   => undef,
    default => "openvox${openvox_release}",
  },
  Optional[String[1]]                 $openvox_server     = undef,
  Optional[String[1]]                 $control_repo       = undef,
  Variant[Boolean, Array[String[1]]]  $autosign           = false,
  Array[String[1]]                    $dns_alt_names      = [],
  Boolean                             $manage_firewall    = true,
  Boolean                             $sign_certs         = true,
  Boolean                             $manage_hosts       = false,
  Optional[String[1]]                 $choria_user        = undef,
) {
  $all = get_targets([$targets, $server_target])

  run_plan(
    'bootstrap::install_agents',
    'targets'            => $all,
    'server_target'      => $server_target,
    'openvox_version'    => $openvox_version ? {
      String[1] => $openvox_version,
      default   => undef,
    },
    'openvox_collection' => $openvox_collection,
    'openvox_server'     => $openvox_server,
  )

  if $manage_hosts {
    # Use the collected facts to build a hash of `host` resources.
    $hosts = $all.reduce({}) |$memo, $target| {
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
    apply($all, '_description' => 'Configure hosts file') {
      $hosts.each |$key, $value| {
        host { $key:
          * => $value,
        }
      }
    }
  }

  if $control_repo {
    # On the server target, configure r10k and deploy the control repo.
    apply($server_target, '_description' => 'Configure r10k') {
      class { 'git': }
      -> class { 'r10k':
        remote   => $control_repo,
        # The default is based on `puppet_vardir`, which is a temporary
        # directory under apply().
        cachedir => '/opt/puppetlabs/puppet/cache/r10k',
      }
      -> exec { 'r10k deploy environment -pv': # lint:ignore:exec_idempotency
        path => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin',
        # Always run this command to ensure that the environment is deployed.
      }
    }
  }

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
    'targets'       => $server_target,
    'server_target' => $server_target,
    'sign_certs'    => $sign_certs,
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
    'targets'       => $all - get_targets($server_target),
    'server_target' => $server_target,
    'sign_certs'    => $sign_certs,
  )
}
