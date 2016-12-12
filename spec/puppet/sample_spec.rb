require 'spec_helper'

# Verify the physical setup of the server
describe interface('eth0') do
    it { should exist }
    it { should be_up }
end

describe interface('eth1') do
    it { should exist }
    it { should be_up }
    it { should have_ipv4_address('192.168.32.5') }
end

# Verify the puppet server configuration
describe package('puppetserver'), :if => os[:family] == 'redhat' do
    it { should be_installed }
end

describe service('puppetserver'), :if => os[:family] == 'redhat' do
    it { should be_enabled }
    it { should be_running }
end

describe port(8140) do
    it { should be_listening }
end

# Verify puppet agent configuration
describe package('puppet-agent') do
    it { should be_installed }
end

describe service('puppet') do
    it { should be_enabled }
    it { should be_running }
end

# General OS setup
describe selinux do
    it { should be_enforcing }
end

# Yum configuration
describe yumrepo('puppetlabs-pc1') do
    it { should exist }
    it { should be_enabled }
end

# Boostrap configuration
# Items in this section are configured during application of bootstrap.pp
describe file('/etc/puppetlabs/puppet/hiera.yaml') do
    it { should be_file }
end

describe package('httpd'), :if => os[:family] == 'redhat' do
  it { should_not be_installed }
end

describe package('apache2'), :if => os[:family] == 'ubuntu' do
  it { should_not be_installed }
end

describe service('httpd'), :if => os[:family] == 'redhat' do
  it { should_not be_enabled }
  it { should_not be_running }
end

describe service('apache2'), :if => os[:family] == 'ubuntu' do
  it { should_not be_enabled }
  it { should_not be_running }
end

describe service('org.apache.httpd'), :if => os[:family] == 'darwin' do
  it { should_not be_enabled }
  it { should_not be_running }
end

describe port(80) do
  it { should_not be_listening }
end
