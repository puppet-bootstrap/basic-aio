# @summary Get signed certificates for hosts from the CA
#
# Each target submits a certificate request, the CA signs it, and the target
# downloads its certificate.  Targets that already have certificates are
# skipped.  Set `server` and `ca_server` on the targets first (see
# `bootstrap::install_agents`).
#
# @param targets The targets that need certificates
# @param ca_target The CA host
# @param dns_alt_names Alternate DNS names to request for every target
plan bootstrap::request_certs (
  TargetSpec       $targets,
  TargetSpec       $ca_target,
  Array[String[1]] $dns_alt_names = [],
) {
  $hosts = get_targets($targets)
  if $hosts.empty {
    return undef
  }

  apply_prep($hosts)
  $certnames = $hosts.reduce({}) |$memo, $target| {
    $memo + { $target.name => $target.facts['networking']['fqdn'] }
  }

  parallelize($hosts) |$target| {
    run_task(
      'bootstrap::cert',
      $target,
      "Requesting a certificate for ${certnames[$target.name]}",
      'action'        => 'request',
      'certname'      => $certnames[$target.name],
      'dns_alt_names' => $dns_alt_names - [$certnames[$target.name]],
    )
  }

  run_task(
    'bootstrap::ca_sign',
    $ca_target,
    'Signing certificates',
    'certnames' => $certnames.values,
  )

  parallelize($hosts) |$target| {
    run_task(
      'bootstrap::cert',
      $target,
      "Downloading the certificate for ${certnames[$target.name]}",
      'action'   => 'download',
      'certname' => $certnames[$target.name],
    )
  }
}
