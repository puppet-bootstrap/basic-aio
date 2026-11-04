# @summary Check that every compile master serves catalogs to every target
#
# Runs `puppet agent --test --noop` on every target against each compile
# master in turn, so a broken compile master shows up now rather than behind
# a load balancer later.  Runs that collide with a running puppet service are
# retried.
#
# @param targets The targets to run the agent on
# @param servers The certnames of the compile masters to test
plan bootstrap::smoke_test (
  TargetSpec       $targets,
  Array[String[1]] $servers,
) {
  $servers.each |$server| {
    run_command(
      @("CMD"/L$),
        for try in 1 2 3 ; do \
          puppet agent --test --noop --detailed-exitcodes --server ${server} ; \
          rc=\$? ; \
          { [ \$rc -eq 0 ] || [ \$rc -eq 2 ] ; } && exit 0 ; \
          sleep 15 ; \
        done ; \
        exit \$rc
        |-CMD
      $targets,
      "No-op agent run against ${server}",
      '_env_vars' => { 'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin' },
    )
  }
}
