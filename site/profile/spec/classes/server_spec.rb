# frozen_string_literal: true

require 'spec_helper'

describe 'profile::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'on the all-in-one server' do
        let(:node) { 'puppet.vagrant' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_firewalld_service('puppetmaster') }

        it {
          is_expected.to contain_class('bootstrap::server').with(
            ca_enabled: true,
            server: 'puppet.vagrant',
            ca_server: 'puppet.vagrant',
          )
        }

        it { is_expected.to contain_class('bootstrap::server::puppetdb').with_puppetdb_urls(['https://puppet.vagrant:8081']) }
      end

      context 'on a compile master with a separate CA and OpenVoxDB' do
        let(:node) { 'compile2.vagrant' }
        let(:pre_condition) do
          <<~PP
            class { 'profile::topology':
              primary    => 'puppet.vagrant',
              server     => 'puppet.vagrant',
              compilers  => ['puppet.vagrant', 'compile2.vagrant'],
              ca_servers => ['ca1.vagrant', 'ca2.vagrant'],
              db_servers => ['db1.vagrant', 'db2.vagrant'],
            }
          PP
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('bootstrap::server').with_ca_enabled(false).with_ca_server('ca1.vagrant') }

        it {
          is_expected.to contain_class('bootstrap::server::puppetdb')
            .with_puppetdb_urls(['https://db1.vagrant:8081', 'https://db2.vagrant:8081'])
        }
      end

      context 'on a standby CA' do
        let(:node) { 'ca2.vagrant' }
        let(:pre_condition) do
          <<~PP
            class { 'profile::topology':
              primary    => 'puppet.vagrant',
              server     => 'puppet.vagrant',
              compilers  => ['puppet.vagrant'],
              ca_servers => ['ca1.vagrant', 'ca2.vagrant'],
              db_servers => ['db1.vagrant'],
            }
          PP
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('bootstrap::server').with_ca_enabled(true).with_ca_server('ca1.vagrant') }
        it { is_expected.not_to contain_class('bootstrap::server::puppetdb') }
      end
    end
  end
end
