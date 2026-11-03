# frozen_string_literal: true

require 'spec_helper'

describe 'bootstrap::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('openvox-server') }
        it { is_expected.to contain_service('puppetserver').with_ensure('running').with_enable(true) }

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/services.d/ca.cfg')
            .with_content(%r{^puppetlabs\.services\.ca\.certificate-authority-service/certificate-authority-service$})
            .that_notifies('Service[puppetserver]')
        }

        it { is_expected.not_to contain_ini_setting('puppet.conf main server') }
        it { is_expected.not_to contain_ini_setting('puppet.conf main crl_refresh_interval') }
        it { is_expected.to contain_file('/etc/systemd/system/openvox-crl-reload.path').with_ensure('absent') }

        it {
          is_expected.to contain_service('openvox-crl-reload.path')
            .with_ensure('stopped')
            .with_enable(false)
            .that_comes_before('File[/etc/systemd/system/openvox-crl-reload.path]')
        }
      end

      context 'without the CA service' do
        let(:params) do
          {
            ca_enabled: false,
            server: 'puppet.example.com',
            ca_server: 'ca.example.com',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/services.d/ca.cfg')
            .with_content(%r{^puppetlabs\.services\.ca\.certificate-authority-disabled-service/certificate-authority-disabled-service$})
            .with_content(%r{^#puppetlabs\.services\.ca\.certificate-authority-service/})
        }

        it { is_expected.to contain_ini_setting('puppet.conf main server').with_value('puppet.example.com') }
        it { is_expected.to contain_ini_setting('puppet.conf main ca_server').with_value('ca.example.com') }
        it { is_expected.to contain_ini_setting('puppet.conf main crl_refresh_interval').with_value('1h') }

        it {
          is_expected.to contain_file('/etc/systemd/system/openvox-crl-reload.path')
            .with_ensure('file')
            .with_content(%r{^PathChanged=/etc/puppetlabs/puppet/ssl/crl\.pem$})
        }

        it { is_expected.to contain_service('openvox-crl-reload.path').with_ensure('running').with_enable(true) }
      end

      context 'without the CA service and without reloading on CRL changes' do
        let(:params) { { ca_enabled: false, reload_on_crl_change: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/systemd/system/openvox-crl-reload.service').with_ensure('absent') }
        it { is_expected.to contain_service('openvox-crl-reload.path').with_ensure('stopped').with_enable(false) }
      end
    end
  end
end
