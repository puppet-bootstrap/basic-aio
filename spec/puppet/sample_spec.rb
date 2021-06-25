require 'spec_helper'

puppet_version = ENV['PUPPET_VERSION'] || ''
puppet_release = puppet_version.empty? ? (ENV['PUPPET_RELEASE'] || '6') : puppet_version.split('.').first

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

# General OS setup
describe selinux do
    it { should be_enforcing }
end

# Initial Boostrap configuration
# Items in this section are configured during application of bootstrap.pp
describe file('/etc/puppetlabs/code/environments/production/hiera.yaml') do
    it { should be_file }
    its(:content_as_yaml) { should include('version' => 5) }

    its(:content_as_yaml) do
        should include(
            'hierarchy' => [
                {
                    'name' => 'FQDN',
                    'path' => 'nodes/%{::trusted.certname}.yaml',
                },
                {
                    'name' => 'Defaults',
                    'path' => 'common.yaml',
                },
            ]
        )
    end
end

describe file('/etc/puppetlabs/r10k/r10k.yaml') do
    it { should be_file }
    its(:content_as_yaml) { should include(:sources => include('puppet' => include('remote' => 'file:///vagrant/') ) ) }
end

describe file('/etc/puppetlabs/code/environments/production') do
    it { should be_directory }
end

describe file('/etc/puppetlabs/code/environments/production/modules/r10k') do
    it { should be_directory }
end

# Vagrant Provisioning configuration
# Items in this section should have been configured by the vagrant provisioning scripts

describe file('/etc/puppetlabs/puppet/autosign.conf') do
    it { should be_file }
    its(:content) { should match %r{^\*\.vagrant$} }
    its(:content) { should match %r{^vagrant\.mcollective$} }
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

# Yum configuration
describe yumrepo("puppet#{puppet_release}") do
    it { should exist }
    it { should be_enabled }
end

# Puppet Boostrap configuration
# Items in this section should have been configured during the initial puppet agent run
describe command('/opt/puppetlabs/bin/puppet module list') do
    its(:stdout) { should match 'puppet-r10k'  }
    its(:stdout) { should match 'puppet-epel' }
    its(:stdout) { should match 'puppetlabs-stdlib' }
end
