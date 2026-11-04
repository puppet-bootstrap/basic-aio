# @summary Configure the certificate authority on a CA host
#
# Use with `bootstrap::server` (with `ca_enabled => true`).
#
# @param autosign
#   `true` to autosign every certificate request, or a list of certnames and
#   domain name globs to write to `autosign.conf`.  `false` leaves autosigning
#   alone.
# @param allow_subject_alt_names
#   Let the CA sign requests that include DNS alt names, which compile masters
#   behind a load balancer need.
#
# @example
#   class { 'bootstrap::ca':
#     autosign => ['*.example.com'],
#   }
class bootstrap::ca (
  Variant[Boolean, Array[String[1]]] $autosign                = false,
  Boolean                            $allow_subject_alt_names = true,
) {
  $confdir = '/etc/puppetlabs/puppet'

  file { '/etc/puppetlabs/puppetserver/conf.d/ca.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('bootstrap/ca.conf.epp', { 'allow_subject_alt_names' => $allow_subject_alt_names }),
    require => Package['openvox-server'],
    notify  => Service['puppetserver'],
  }

  case $autosign {
    Array: {
      file { "${confdir}/autosign.conf":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $autosign.map |$entry| { "${entry}\n" }.join,
      }
      # Point `autosign` at the file, in case it was `true` before.
      ini_setting { 'puppet.conf server autosign':
        ensure  => present,
        path    => "${confdir}/puppet.conf",
        section => 'server',
        setting => 'autosign',
        value   => "${confdir}/autosign.conf",
        notify  => Service['puppetserver'],
      }
    }
    true: {
      ini_setting { 'puppet.conf server autosign':
        ensure  => present,
        path    => "${confdir}/puppet.conf",
        section => 'server',
        setting => 'autosign',
        value   => 'true',
        notify  => Service['puppetserver'],
      }
    }
    default: {}
  }
}
