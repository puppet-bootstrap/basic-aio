node 'puppet.vagrant' {
  class { 'r10k':
    remote => 'https://github.com/silug/basic-aio.git'
  }

  class {'hiera':
        hierarchy => ['nodes/%{::trusted.certname}','common'],
  }
}
