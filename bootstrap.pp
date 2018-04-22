node 'puppet.vagrant' {
  class { 'r10k':
    remote => 'https://github.com/puppet-bootstrap/basic-aio.git'
  }

  exec { 'r10k deploy environment -pv':
    path    => '/opt/puppetlabs/bin:/bin:/sbin',
    creates => '/etc/puppetlabs/code/environments/production/Puppetfile',
  }
}
