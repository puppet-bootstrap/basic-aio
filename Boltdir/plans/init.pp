# @summary Bootstrap an OpenVox server infrastructure and agents
#
# Uses the plans in the `bootstrap` module to set up the CA, OpenVoxDB, and
# compile masters, optionally deploying a control repo to every compile
# master with r10k before the first agent run.  By default, the CA runs on
# `server_target` and OpenVoxDB isn't installed.
#
# `vagrant up` runs this plan with `manage_hosts`, `control_repo`,
# `choria_user`, and `manage_topology_data` set for the demo environment.
#
# @param targets The agent targets.  The infrastructure hosts are added to them.
# @param server_target The primary compile master
# @param compilers Additional compile masters
# @param ca_targets
#   The CA hosts.  The first is the active CA; any others are standbys with a
#   copy of its CA directory.  Defaults to `server_target`.
# @param db_targets
#   The OpenVoxDB hosts.  The first one also runs PostgreSQL.  OpenVoxDB isn't
#   installed if this is empty.
# @param db_password
#   Password for the OpenVoxDB PostgreSQL user.  Required if `db_targets` is
#   set.
# @param openvox_release The major version of OpenVox to install
# @param openvox_version
#   The version of openvox-agent to install.  Defaults to the latest version
#   in `openvox_collection`.  Installing openvox-server may upgrade the agent
#   on the server to satisfy openvox-server's dependencies.
# @param openvox_collection
#   The collection to install from.  Defaults to `openvox${openvox_release}`
#   when `openvox_release` is set, `openvox9` when neither `openvox_release`
#   nor `openvox_version` is set, and otherwise the collection matching
#   `openvox_version`.  Only used with `manage_repos`.
# @param openvox_server
#   The value of `server` in `puppet.conf`.  Defaults to the FQDN of
#   `server_target`.  (OpenVox 9 no longer defaults `server` to `puppet`.)
# @param control_repo
#   URL of a control repo to deploy to every compile master with r10k before
#   the first agent run.  No code is deployed if this isn't set.
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf` on the CAs.  `false` leaves
#   autosigning alone.
# @param dns_alt_names Alternate DNS names for the compile masters' certificates
# @param manage_firewall Open the needed ports in firewalld, if firewalld is running
# @param sign_certs Sign certificate requests for agents whose first run fails
# @param manage_repos
#   Set up the OpenVox package repository (and, for OpenVoxDB, the PostgreSQL
#   repository).  Set this to `false` on hosts that can't reach the internet
#   but already have the packages available, such as from a Satellite.
# @param manage_hosts
#   Add every target to every target's hosts file, using the facts collected
#   from them.  Useful when the targets can't resolve each other's names.
# @param choria_user
#   If set, request a Choria certificate for this user on the primary compile
#   master after its first agent run.  The control repo must set up Choria.
# @param manage_topology_data
#   Write the infrastructure layout (and `db_password`) into the global Hiera
#   layer on the compile masters, as the `basic_aio::*` keys this repo's
#   control code uses.  This replaces the global `hiera.yaml`.
# @param smoke_test
#   If there is more than one compile master, run the agent in no-op mode on
#   every target against each of them
plan basic_aio (
  TargetSpec                                         $targets,
  TargetSpec                                         $server_target,
  TargetSpec                                         $compilers            = [],
  Optional[TargetSpec]                               $ca_targets           = undef,
  TargetSpec                                         $db_targets           = [],
  Optional[Variant[String[1], Sensitive[String[1]]]] $db_password          = undef,
  Optional[Integer]                                  $openvox_release      = undef,
  Optional[String]                                   $openvox_version      = undef,
  Optional[String[1]]                                $openvox_collection   = $openvox_release ? {
    undef   => $openvox_version ? {
      undef   => 'openvox9',
      default => undef,
    },
    default => "openvox${openvox_release}",
  },
  Optional[String[1]]                                $openvox_server       = undef,
  Optional[String[1]]                                $control_repo         = undef,
  Variant[Boolean, Array[String[1]]]                 $autosign             = false,
  Array[String[1]]                                   $dns_alt_names        = [],
  Boolean                                            $manage_firewall      = true,
  Boolean                                            $sign_certs           = true,
  Boolean                                            $manage_hosts         = false,
  Boolean                                            $manage_repos         = true,
  Optional[String[1]]                                $choria_user          = undef,
  Boolean                                            $manage_topology_data = false,
  Boolean                                            $smoke_test           = true,
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
    'openvox_version'    => $openvox_version ? {
      String[1] => $openvox_version,
      default   => undef,
    },
    'openvox_collection' => $openvox_collection,
    'openvox_server'     => $openvox_server,
    'autosign'           => $autosign,
    'dns_alt_names'      => $dns_alt_names,
    'manage_firewall'    => $manage_firewall,
    'manage_hosts'       => $manage_hosts,
    'manage_repos'       => $manage_repos,
  )

  $primary = get_targets($server_target)
  $servers = ($primary + get_targets($compilers)).unique
  $cas = $ca_targets ? {
    undef   => $primary,
    default => get_targets($ca_targets),
  }
  $all = get_targets([$targets, $server_target, $compilers, $ca_targets, $db_targets].filter |$spec| { $spec =~ NotUndef })

  if $manage_topology_data {
    $password_data = $database_password ? {
      undef   => {},
      default => { 'basic_aio::db_password' => $database_password.unwrap },
    }
    $data = {
      'basic_aio::primary'    => $topology['primary'],
      'basic_aio::server'     => $topology['server'],
      'basic_aio::compilers'  => $topology['compilers'],
      'basic_aio::ca_servers' => $topology['ca_servers'],
      'basic_aio::db_servers' => $topology['db_servers'],
      'basic_aio::manage_repos' => $manage_repos,
    } + $password_data

    apply($servers, '_description' => 'Writing the infrastructure layout to Hiera') {
      file { '/etc/puppetlabs/puppet/hiera.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => @(HIERA),
          ---
          # Managed by Bolt (basic_aio).
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "basic-aio topology"
              path: "basic_aio.yaml"
          | HIERA
      }

      file { '/etc/puppetlabs/puppet/data':
        ensure => directory,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0750',
      }

      file { '/etc/puppetlabs/puppet/data/basic_aio.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'puppet',
        mode    => '0640',
        content => Sensitive("# Managed by Bolt (basic_aio).\n${data.to_yaml}"),
      }

      ~> exec { 'basic_aio reload puppetserver':
        command     => 'systemctl reload puppetserver',
        path        => ['/usr/bin', '/bin'],
        refreshonly => true,
      }
    }
  }

  if $control_repo {
    # On every compile master, configure r10k and deploy the control repo.
    apply($servers, '_description' => 'Configure r10k') {
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
    'bootstrap::first_run',
    'targets'       => $primary,
    'server_target' => $primary,
    'ca_target'     => $cas[0],
    'sign_certs'    => $sign_certs,
  )

  if $choria_user {
    # Request a choria cert.
    apply(
      $primary,
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
    'targets'       => $all - $primary,
    'server_target' => $primary,
    'ca_target'     => $cas[0],
    'sign_certs'    => $sign_certs,
  )

  # Copy certificates signed during the agent runs to any standby CAs.
  run_plan('bootstrap::sync_ca', 'active' => $cas[0], 'standbys' => $cas[1, -1])

  if $smoke_test and $topology['compilers'].length > 1 {
    run_plan('bootstrap::smoke_test', 'targets' => $all, 'servers' => $topology['compilers'])
  }
}
