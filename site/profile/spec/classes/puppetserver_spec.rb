require 'spec_helper'

describe 'profile::puppetserver' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('profile::puppetserver') }

      it { is_expected.to contain_class('profile::puppetserver::install').that_comes_before('Class[profile::puppetserver::config]') }
      it { is_expected.to contain_class('profile::puppetserver::config').that_comes_before('Class[profile::puppetserver::service]').that_notifies('Class[profile::puppetserver::service]') }
      it { is_expected.to contain_class('profile::puppetserver::service') }
    end
  end
end
