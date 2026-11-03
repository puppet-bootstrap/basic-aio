# frozen_string_literal: true

require 'spec_helper'

describe 'bootstrap::ca' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include bootstrap::server' }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/ca.conf')
            .with_content(%r{^\s+allow-subject-alt-names: true$})
        }

        it { is_expected.not_to contain_file('/etc/puppetlabs/puppet/autosign.conf') }
        it { is_expected.not_to contain_ini_setting('puppet.conf server autosign') }
      end

      context 'with a list of autosign entries' do
        let(:params) { { autosign: ['*.example.com', 'special.example.org'] } }

        it { is_expected.to contain_file('/etc/puppetlabs/puppet/autosign.conf').with_content("*.example.com\nspecial.example.org\n") }
        it { is_expected.to contain_ini_setting('puppet.conf server autosign').with_value('/etc/puppetlabs/puppet/autosign.conf') }
      end

      context 'with autosign enabled' do
        let(:params) { { autosign: true } }

        it { is_expected.to contain_ini_setting('puppet.conf server autosign').with_value('true') }
        it { is_expected.not_to contain_file('/etc/puppetlabs/puppet/autosign.conf') }
      end
    end
  end
end
