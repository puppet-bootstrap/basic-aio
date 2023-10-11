# frozen_string_literal: true

Facter.add(:role__puppetserver__r10k_remote) do
  r10k_yaml = '/etc/puppetlabs/r10k/r10k.yaml'

  confine kernel: 'Linux'
  confine do
    File.exist?(r10k_yaml)
  end

  setcode do
    require 'yaml'

    config = YAML.load_file(r10k_yaml)

    config.dig(:sources, 'puppet', 'remote')
  rescue
    nil
  end
end
