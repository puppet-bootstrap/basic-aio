node puppet.vagrant {
  class { 'r10k':
    remote => 'https://github.com/puppet-bootstrap/basic-aio.git'
  }

  class {'hiera':
        hierarchy => ["nodes/%{::trusted.certname}",'common'],
  }
}
