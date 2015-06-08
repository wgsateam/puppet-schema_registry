source 'https://rubygems.org'

group :test do
  # https://github.com/rspec/rspec-core/issues/1864
  rspecversion = ENV.key?('RSPEC_VERSION') ? "= #{ENV['RSPEC_VERSION']}" : ['< 3.2.0']
  gem 'rspec', rspecversion

  # Rake 10.2.0 requires Ruby >= 1.9
  gem 'rake', '< 10.2.0' if RUBY_VERSION < '1.9.0'
  gem 'puppet', ENV['PUPPET_VERSION'] || '~> 3.0.1'
  gem 'puppet-lint'
  # or: gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'rspec-puppet', '~> 2.1.0'
  gem 'puppet-syntax'
  gem 'puppetlabs_spec_helper'
end

group :development do
  gem 'travis'
  gem 'travis-lint'
  gem 'beaker'
  gem 'beaker-rspec'
  gem 'vagrant-wrapper'
  gem 'puppet-blacksmith'
  gem 'guard-rake'
  gem 'serverspec'
end
