node 'puppet.vagrant' {
  class { 'r10k':
    remote => 'file:///vagrant/'
  }

  exec { 'r10k deploy environment -pv':
    path    => '/opt/puppetlabs/bin:/bin:/usr/bin:/sbin:/usr/sbin',
    creates => '/etc/puppetlabs/code/environments/production/Puppetfile',
  }
}
