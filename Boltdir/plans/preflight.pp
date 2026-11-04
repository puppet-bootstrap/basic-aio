# @summary Check that the targets are ready for `basic_aio` without changing them
#
# Accepts the same parameters as `basic_aio`, so you can check a command line
# by changing only the plan name, and runs `bootstrap::preflight`.  With
# `control_repo`, it also checks that the compile masters can reach
# rubygems.org and forge.puppet.com, which r10k needs.  Parameters that
# don't affect the checks are accepted and ignored.
#
# @param targets The agent targets
# @param server_target The primary compile master
# @param compilers Additional compile masters
# @param ca_targets The CA hosts
# @param db_targets The OpenVoxDB hosts
# @param db_password Must be set if `db_targets` is set
# @param openvox_release Ignored
# @param openvox_version Ignored
# @param openvox_collection Ignored
# @param openvox_server The value of `server` in `puppet.conf`
# @param control_repo URL of the control repo to deploy with r10k
# @param autosign Ignored
# @param dns_alt_names Ignored
# @param manage_firewall Ignored
# @param sign_certs Ignored
# @param manage_hosts Whether `basic_aio` will manage hosts files
# @param alias_server_names Whether `basic_aio` will add `openvox_server` to hosts files
# @param manage_repos Whether `basic_aio` will set up package repositories
# @param postgres_source Where PostgreSQL will come from (`pgdg` or `os`)
# @param postgres_version The PostgreSQL major version
# @param choria_user Ignored
# @param manage_topology_data Ignored
# @param smoke_test Ignored
#
# @return [Hash] Each target's FQDN, errors, and warnings
plan basic_aio::preflight (
  TargetSpec                                         $targets,
  TargetSpec                                         $server_target,
  TargetSpec                                         $compilers            = [],
  Optional[TargetSpec]                               $ca_targets           = undef,
  TargetSpec                                         $db_targets           = [],
  Optional[Variant[String[1], Sensitive[String[1]]]] $db_password          = undef,
  Optional[Integer]                                  $openvox_release      = undef,
  Optional[String]                                   $openvox_version      = undef,
  Optional[String[1]]                                $openvox_collection   = undef,
  Optional[String[1]]                                $openvox_server       = undef,
  Optional[String[1]]                                $control_repo         = undef,
  Variant[Boolean, Array[String[1]]]                 $autosign             = false,
  Array[String[1]]                                   $dns_alt_names        = [],
  Boolean                                            $manage_firewall      = true,
  Boolean                                            $sign_certs           = true,
  Boolean                                            $manage_hosts         = false,
  Boolean                                            $alias_server_names   = false,
  Boolean                                            $manage_repos         = true,
  Enum['pgdg', 'os']                                 $postgres_source      = 'pgdg',
  Optional[String[1]]                                $postgres_version     = undef,
  Optional[String[1]]                                $choria_user          = undef,
  Boolean                                            $manage_topology_data = false,
  Boolean                                            $smoke_test           = true,
) {
  $missing_password = !get_targets($db_targets).empty and $db_password =~ Undef

  $server_urls = $control_repo ? {
    undef   => [],
    default => ['https://rubygems.org/', 'https://forge.puppet.com/'],
  }

  $result = run_plan(
    'bootstrap::preflight',
    'targets'            => $targets,
    'server_target'      => $server_target,
    'compilers'          => $compilers,
    'ca_targets'         => $ca_targets,
    'db_targets'         => $db_targets,
    'openvox_server'     => $openvox_server,
    'manage_repos'       => $manage_repos,
    'manage_hosts'       => $manage_hosts,
    'alias_server_names' => $alias_server_names,
    'postgres_source'    => $postgres_source,
    'postgres_version'   => $postgres_version,
    'server_urls'        => $server_urls,
    '_catch_errors'      => true,
  )

  if $missing_password {
    out::message('FAILED: db_password is required when db_targets is set')
  }

  if $result =~ Error {
    fail_plan($result)
  } elsif $missing_password {
    fail_plan('db_password is required when db_targets is set', 'bootstrap/preflight-failed')
  }

  return $result
}
