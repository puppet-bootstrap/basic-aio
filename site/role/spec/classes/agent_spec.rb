require 'spec_helper'

describe 'role::agent' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it { is_expected.to contain_class('role::agent') }

      it { is_expected.to contain_class('profile::base') }
      it { is_expected.to contain_class('profile::agent') }
    end
  end
end
