require 'rake'
require 'rspec/core/rake_task'

task default: :spec

desc 'Run serverspec tests on all targets'
task spec: 'spec:all'

namespace :spec do
  targets = []
  Dir.glob('./spec/*').each do |dir|
    next unless File.directory?(dir)
    target = File.basename(dir)
    target = "_#{target}" if target == 'default'
    targets << target
  end

  task default: :all

  desc 'Run serverspec tests on all targets'
  task all: targets

  targets.each do |target|
    original_target = (target == '_default') ? target[1..-1] : target
    desc "Run serverspec tests on #{original_target}"
    RSpec::Core::RakeTask.new(target.to_sym) do |t|
      ENV['TARGET_HOST'] = original_target
      t.pattern = "spec/#{original_target}/*_spec.rb"
    end
  end
end
