# @summary Move a certificate generated on the CA to the host it belongs to
#
# Moves the certificate and keys that `bootstrap::ca_generate` created on the
# CA into the target's SSL directory, then downloads the CA certificate and
# CRL there.  The private key passes through the Bolt host's `downloads`
# directory and is deleted from it and from the CA afterward.  For targets
# that already have the certificate, only the last steps (downloading the CA
# certificate and CRL, and removing the keys from the CA) are repeated, in
# case an earlier run stopped partway.
#
# @param ca_target The CA host where the certificate was generated
# @param targets The hosts to move certificates to.  Each one's certname is its FQDN.
plan bootstrap::copy_cert (
  TargetSpec $ca_target,
  TargetSpec $targets,
) {
  $hosts = get_targets($targets)
  if $hosts.empty {
    return undef
  }
  apply_prep($hosts)

  $env_vars = { 'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin' }
  $ssldir = run_command(
    'puppet config print ssldir',
    $ca_target,
    'Finding the SSL directory',
    '_env_vars' => $env_vars,
  )[0]['stdout'].strip

  $hosts.each |$target| {
    $certname = $target.facts['networking']['fqdn']
    $files = ['certs', 'private_keys', 'public_keys'].map |$dir| { "${dir}/${certname}.pem" }
    $archive = "/root/openvox-cert-${certname}.tar.gz"

    $existing = run_command(
      "test -f ${ssldir}/certs/${certname}.pem && echo yes || echo no",
      $target,
      "Checking for a certificate on ${certname}",
    )[0]['stdout'].strip
    if $existing != 'yes' {
      run_command(
        "umask 077 && tar -C ${ssldir} -czf ${archive} ${files.join(' ')}",
        $ca_target,
        "Archiving the certificate for ${certname}",
      )
      $local = download_file($archive, 'openvox-cert', $ca_target, "Downloading the certificate for ${certname}")[0]['path']
      upload_file($local, $archive, $target, "Uploading the certificate for ${certname}")
      file::delete($local)

      run_command(
        @("CMD"/L),
          mkdir -p ${ssldir}/certs ${ssldir}/private_keys ${ssldir}/public_keys && \
          tar -C ${ssldir} -xzf ${archive} && rm -f ${archive}
          |-CMD
        $target,
        "Installing the certificate for ${certname}",
      )
    }

    # These are safe to repeat.
    run_command(
      "puppet ssl bootstrap --certname ${certname} --waitforcert 0",
      $target,
      "Downloading the CA certificate and CRL to ${certname}",
      '_env_vars' => $env_vars,
    )

    # The CA keeps its copy of the certificate in the CA directory.
    run_command(
      "rm -f ${archive} ${files.map |$f| { "${ssldir}/${f}" }.join(' ')}",
      $ca_target,
      "Removing ${certname}'s keys from the CA",
    )
  }
}
