# @summary Copy the CA directory from the active CA to standby CAs
#
# The copy passes through the Bolt host's `downloads` directory and is
# deleted afterward.  Run this again after the active CA signs or revokes
# certificates to keep the standbys current.  Don't point agents at a
# standby until it is promoted, or its serial numbers will diverge.
#
# @param active The active CA host
# @param standbys The standby CA hosts
plan bootstrap::sync_ca (
  TargetSpec $active,
  TargetSpec $standbys,
) {
  $standby_targets = get_targets($standbys)
  if $standby_targets.empty {
    return undef
  }

  $env_vars = { 'PATH' => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin' }
  $archive = '/root/openvox-ca-sync.tar.gz'

  $cadir = run_command(
    'puppet config print cadir --section server',
    $active,
    'Finding the CA directory',
    '_env_vars' => $env_vars,
  )[0]['stdout'].strip

  run_command(
    "umask 077 && tar -C ${cadir} -czf ${archive} .",
    $active,
    'Archiving the CA directory',
  )

  $local = download_file($archive, 'openvox-ca-sync', $active, 'Downloading the CA directory')[0]['path']
  run_command("rm -f ${archive}", $active, 'Removing the archive from the active CA')

  upload_file($local, $archive, $standby_targets, 'Uploading the CA directory')
  file::delete($local)

  run_command(
    "mkdir -p ${cadir} && tar -C ${cadir} -xzf ${archive} && chown -R puppet:puppet ${cadir} && rm -f ${archive}",
    $standby_targets,
    'Unpacking the CA directory',
  )
}
