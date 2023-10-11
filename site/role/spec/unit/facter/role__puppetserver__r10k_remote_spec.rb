# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/role__puppetserver__r10k_remote'

describe :role__puppetserver__r10k_remote, type: :fact do
  subject(:fact) { Facter.fact(:role__puppetserver__r10k_remote) }

  let(:r10k_yaml) { '/etc/puppetlabs/r10k/r10k.yaml' }
  let(:r10k_config) do
    {
      cachedir: '/opt/puppetlabs/puppet/cache/r10k',
      sources: {
        'puppet' => {
          'basedir' => '/etc/puppetlabs/code/environments',
          'remote'  => 'file:///vagrant',
        },
      },
    }
  end

  before :each do
    Facter.clear
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with r10k.yaml' do
        before :each do
          allow(File).to receive(:exist?).with(r10k_yaml).and_return(true)
          allow(YAML).to receive(:load_file).with(r10k_yaml).and_return(r10k_config)
        end

        it 'returns a value' do
          expect(fact.value).to eq('file:///vagrant')
        end
      end

      context 'with no r10k.yaml' do
        before :each do
          allow(File).to receive(:exist?).with(r10k_yaml).and_return(false)
        end

        it 'returns a value' do
          expect(fact.value).to be_nil
        end
      end
    end
  end
end
