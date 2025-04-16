# @summary Configures the puppet server
#
# @param autosign List of certnames or domain name globs
#
# @example
#   include profile::server::config
class profile::server::config (
  Array[String] $autosign,
) {
  file { '/etc/puppetlabs/puppet/autosign.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/autosign.conf.epp'),
  }
}
