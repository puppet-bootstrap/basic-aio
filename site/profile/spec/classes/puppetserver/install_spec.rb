require 'spec_helper'

describe 'profile::puppetserver::install' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('profile::puppetserver::install') }

      it { is_expected.to contain_package('puppetserver').with('ensure' => 'installed') }
    end
  end
end
