require 'spec_helper'

describe 'profile::puppetserver::service' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('profile::puppetserver::service') }

      it { is_expected.to contain_class('puppetdb::master::config') }

      it {
        is_expected.to contain_service('puppetserver').with(
          'ensure' => 'running',
          'enable' => true,
        )
      }
    end
  end
end
