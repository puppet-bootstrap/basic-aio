# frozen_string_literal: true

require 'spec_helper'

describe 'bootstrap::server::puppetdb' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include bootstrap::server' }
      let(:params) do
        { puppetdb_urls: ['https://db1.example.com:8081', 'https://db2.example.com:8081'] }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_package('openvoxdb-termini') }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppet/puppetdb.conf')
          .with_content(%r{^server_urls = https://db1\.example\.com:8081,https://db2\.example\.com:8081$})
          .that_notifies('Service[puppetserver]')
      }

      it { is_expected.to contain_file('/etc/puppetlabs/puppet/routes.yaml').with_content(%r{terminus: puppetdb}) }
      it { is_expected.to contain_ini_setting('puppet.conf server storeconfigs_backend').with_value('puppetdb') }
      it { is_expected.to contain_ini_setting('puppet.conf server reports').with_value('store,puppetdb') }
    end
  end
end
