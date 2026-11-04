# frozen_string_literal: true

require 'spec_helper'

describe 'bootstrap::db' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with a local PostgreSQL server' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            certificate_allowlist: ['puppet.example.com'],
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_class('openvoxdb').with(
            manage_dbserver: true,
            database_host: 'localhost',
            database_listen_address: 'localhost',
            certificate_whitelist: ['puppet.example.com'],
            postgres_version: '17',
            manage_firewall: false,
          )
        }

        it { is_expected.not_to contain_postgresql__server__pg_hba_rule('openvoxdb on db2.example.com') }
      end

      context 'with remote OpenVoxDB hosts' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            remote_clients: ['db2.example.com'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('openvoxdb').with_database_listen_address('0.0.0.0') }

        it {
          is_expected.to contain_postgresql__server__pg_hba_rule('openvoxdb on db2.example.com').with(
            address: 'db2.example.com',
            auth_method: 'scram-sha-256',
          )
        }
      end

      context 'connecting to a remote PostgreSQL server' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            manage_dbserver: false,
            database_host: 'db1.example.com',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('openvoxdb').with_manage_dbserver(false).with_manage_database(false).with_database_host('db1.example.com') }
        it { is_expected.not_to contain_class('postgresql::server') }
      end
    end
  end
end
