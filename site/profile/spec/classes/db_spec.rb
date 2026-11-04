# frozen_string_literal: true

require 'spec_helper'

describe 'profile::db' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'on the all-in-one server' do
        let(:node) { 'puppet.vagrant' }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_class('bootstrap::db').with(
            manage_dbserver: true,
            certificate_allowlist: ['puppet.vagrant'],
            remote_clients: [],
            postgres_version: '17',
          )
        }

        it { is_expected.to contain_firewalld_port('openvoxdb').with_port(8081) }
        it { is_expected.not_to contain_firewalld_port('postgresql') }
      end

      context 'with several OpenVoxDB hosts' do
        let(:pre_condition) do
          <<~PP
            class { 'profile::topology':
              primary    => 'puppet.vagrant',
              server     => 'puppet.vagrant',
              compilers  => ['puppet.vagrant', 'compile2.vagrant'],
              ca_servers => ['ca1.vagrant'],
              db_servers => ['db1.vagrant', 'db2.vagrant'],
            }
          PP
        end

        context 'on the PostgreSQL host' do
          let(:node) { 'db1.vagrant' }

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to contain_class('bootstrap::db').with(
              manage_dbserver: true,
              certificate_allowlist: ['puppet.vagrant', 'compile2.vagrant'],
              remote_clients: ['db2.vagrant'],
            )
          }

          it { is_expected.to contain_firewalld_port('postgresql').with_port(5432) }
        end

        context 'on another OpenVoxDB host' do
          let(:node) { 'db2.vagrant' }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('bootstrap::db').with_manage_dbserver(false).with_database_host('db1.vagrant') }
          it { is_expected.not_to contain_firewalld_port('postgresql') }
        end
      end
    end
  end
end
