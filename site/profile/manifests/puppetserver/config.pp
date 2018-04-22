# profile::puppetserver::config
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::puppetserver::config
class profile::puppetserver::config (
  Array[String] $autosign,
){
  file { '/etc/puppetlabs/puppet/autosign.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('profile/autosign.conf.epp'),
  }
}
