# @summary Run the OpenVox agent for the first time
#
# Runs the agent on the server first (if it is one of the targets), then on
# the remaining targets.  If an agent's first run fails, probably because its
# certificate hasn't been signed, its certificate request is signed on the
# CA and the agent is run again.  Finally, the puppet service is started.
#
# @param targets The targets to run the agent on
# @param server_target The OpenVox server target
# @param ca_target The CA target.  Defaults to `server_target`.
# @param sign_certs Sign certificate requests for agents whose first run fails
# @param start_service Start and enable the puppet service after the first run
plan bootstrap::first_run (
  TargetSpec $targets,
  TargetSpec $server_target,
  TargetSpec $ca_target     = $server_target,
  Boolean    $sign_certs    = true,
  Boolean    $start_service = true,
) {
  $env_vars = { 'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin' }

  $server = get_targets($server_target)[0]
  $all = get_targets($targets)
  $agents = $all - $server

  if $server in $all {
    run_command(
      'puppet agent --test --detailed-exitcodes || [ $? -eq 2 ]',
      $server,
      'First agent run on the server',
      '_env_vars' => $env_vars,
    )
  }

  unless $agents.empty {
    $first = run_command(
      'puppet agent --test --detailed-exitcodes --waitforcert 0 || [ $? -eq 2 ]',
      $agents,
      'First agent run',
      '_env_vars'     => $env_vars,
      '_catch_errors' => true,
    )

    unless $first.ok {
      if !$sign_certs {
        fail_plan($first.error_set.first.error)
      }

      $unsigned = $first.error_set.targets
      $certnames = run_command(
        'puppet config print certname',
        $unsigned,
        'Looking up certnames',
        '_env_vars' => $env_vars,
      ).map |$result| { $result['stdout'].strip }

      run_command(
        "puppetserver ca sign --certname ${certnames.join(',')}",
        $ca_target,
        'Signing certificates',
        '_env_vars' => $env_vars,
      )

      run_command(
        'puppet agent --test --detailed-exitcodes || [ $? -eq 2 ]',
        $unsigned,
        'Second agent run',
        '_env_vars' => $env_vars,
      )
    }
  }

  if $start_service {
    run_task(
      'openvox_bootstrap::configure',
      $all,
      'Starting the puppet service',
      'puppet_service_running' => true,
      'puppet_service_enabled' => true,
    )
  }
}
