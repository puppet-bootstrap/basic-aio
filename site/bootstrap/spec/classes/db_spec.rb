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

      context 'without managing the PGDG repository' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            manage_package_repo: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('openvoxdb').with_manage_package_repo(false) }
        it { is_expected.not_to contain_yumrepo('yum.postgresql.org') }
        it { is_expected.to contain_package('postgresql-server').with_name('postgresql17-server') }
      end

      context 'with the operating system PostgreSQL packages' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            postgres_source: 'os',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_class('openvoxdb').with(
            manage_dbserver: false,
            manage_database: true,
            manage_package_repo: false,
            postgres_version: '16',
          )
        }

        it { is_expected.to contain_class('postgresql::globals').with_manage_package_repo(false).with_version('16') }
        it { is_expected.to contain_class('postgresql::server').with_listen_addresses('localhost') }
        it { is_expected.to contain_package('postgresql-server').with_name('postgresql-server') }
        it { is_expected.to contain_package('postgresql-contrib').with_name('postgresql-contrib') }
        it { is_expected.to contain_postgresql__server__extension('pg_trgm').with_database('puppetdb') }
        it { is_expected.to contain_postgresql__server__db('puppetdb') }
        it { is_expected.not_to contain_yumrepo('yum.postgresql.org') }
        it { is_expected.not_to contain_package('postgresql-dnfmodule') }

        if ['8', '9'].include?(os_facts[:os]['release']['major'])
          it { is_expected.to contain_package('postgresql dnf module').with_ensure('16').with_enable_only(true) }
        else
          it { is_expected.not_to contain_package('postgresql dnf module') }
        end
      end

      context 'with the operating system PostgreSQL 18 packages' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            postgres_source: 'os',
            postgres_version: '18',
          }
        end

        if os_facts[:os]['release']['major'] == '10'
          it { is_expected.to compile.and_raise_error(%r{supports only PostgreSQL 16 on EL 10}) }
        else
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_package('postgresql dnf module').with_ensure('18') }
          it { is_expected.to contain_package('postgresql-server').with_name('postgresql-server') }
        end
      end

      context 'with the operating system PostgreSQL packages and remote OpenVoxDB hosts' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            postgres_source: 'os',
            remote_clients: ['db2.example.com'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('postgresql::server').with_listen_addresses('0.0.0.0') }
        it { is_expected.to contain_postgresql__server__pg_hba_rule('openvoxdb on db2.example.com') }
      end

      context 'with the operating system PostgreSQL packages connecting to a remote server' do
        let(:params) do
          {
            database_password: sensitive('secret'),
            postgres_source: 'os',
            manage_dbserver: false,
            database_host: 'db1.example.com',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('openvoxdb').with_manage_dbserver(false).with_manage_database(false) }
        it { is_expected.not_to contain_class('postgresql::server') }
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
