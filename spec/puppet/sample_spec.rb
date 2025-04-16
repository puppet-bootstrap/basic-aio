# frozen_string_literal: true

require 'spec_helper'

openvox_version = ENV.fetch('OPENVOX_VERSION', '')
openvox_release = openvox_version.empty? ? ENV.fetch('OPENVOX_RELEASE', '8') : openvox_version.split('.').first

describe 'server' do
  # Verify the physical setup of the server
  describe interface('eth0') do
    it { is_expected.to exist }
    it { is_expected.to be_up }
  end

  describe interface('eth1') do
    it { is_expected.to exist }
    it { is_expected.to be_up }
    it { is_expected.to have_ipv4_address('192.168.32.5') }
  end

  # General OS setup
  describe selinux do
    it { is_expected.to be_enforcing }
  end

  # Initial Boostrap configuration
  # Items in this section are configured during application of bootstrap.pp
  describe file('/etc/puppetlabs/code/environments/production/hiera.yaml') do
    it { is_expected.to be_file }
    its(:content_as_yaml) { is_expected.to include('version' => 5) }

    its(:content_as_yaml) do
      is_expected.to include(
          'hierarchy' => [
            {
              'name' => 'FQDN',
              'path' => 'nodes/%{trusted.certname}.yaml',
            },
            {
              'name' => 'Defaults',
              'path' => 'common.yaml',
            },
          ],
        )
    end
  end

  describe file('/etc/puppetlabs/r10k/r10k.yaml') do
    it { is_expected.to be_file }
    its(:content_as_yaml) do
      is_expected.to include(sources: include('puppet' => include('remote' => 'file:///vagrant/')))
        .or include('sources' => include('puppet' => include('remote' => 'file:///vagrant/')))
    end
  end

  describe file('/etc/puppetlabs/code/environments/production') do
    it { is_expected.to be_directory }
  end

  describe file('/etc/puppetlabs/code/environments/production/modules/r10k') do
    it { is_expected.to be_directory }
  end

  # Vagrant Provisioning configuration
  # Items in this section should have been configured by the vagrant provisioning scripts

  describe file('/etc/puppetlabs/puppet/autosign.conf') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match %r{^\*\.vagrant$} }
    its(:content) { is_expected.to match %r{^vagrant\.mcollective$} }
  end

  # Verify the puppet server configuration
  describe package('openvox-server'), if: os[:family] == 'redhat' do
    it { is_expected.to be_installed }
  end

  describe service('puppetserver'), if: os[:family] == 'redhat' do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe port(8140) do
    it { is_expected.to be_listening }
  end

  # Verify puppet agent configuration
  describe package('openvox-agent') do
    it { is_expected.to be_installed }
  end

  describe service('puppet') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  # Yum configuration
  describe yumrepo("openvox#{openvox_release}") do
    it { is_expected.to exist }
    it { is_expected.to be_enabled }
  end

  # Puppet Boostrap configuration
  # Items in this section should have been configured during the initial puppet agent run
  describe command('/opt/puppetlabs/bin/puppet module list') do
    its(:stdout) { is_expected.to match 'puppet-r10k' }
    its(:stdout) { is_expected.to match 'puppet-epel' }
    its(:stdout) { is_expected.to match 'puppetlabs-stdlib' }
  end
end
