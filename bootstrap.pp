node 'puppet.vagrant' {
  class { 'r10k':
    remote => 'https://github.com/puppet-bootstrap/basic-aio.git'
  }
}
