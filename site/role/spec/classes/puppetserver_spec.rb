require 'spec_helper'

describe 'role::puppetserver' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          'puppet_environmentpath' => '/etc/puppetlabs/code/environments',
          'puppet_vardir'          => '/opt/puppetlabs/puppet/cache',
        )
      end

      it { is_expected.to compile }

      it { is_expected.to contain_class('role::puppetserver') }

      it { is_expected.to contain_class('r10k') }
      it { is_expected.to contain_class('puppetdb') }
      it { is_expected.to contain_class('puppetdb::master::config') }
      it { is_expected.to contain_class('choria').with('manage_package_repo' => true) }
      it { is_expected.to contain_class('choria::broker').with('network_broker' => true) }
    end
  end
end
