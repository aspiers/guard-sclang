# -*- encoding: utf-8 -*-
require File.expand_path("../lib/guard/sclang/version", __FILE__)

Gem::Specification.new do |s|
  s.name         = "guard-sclang"
  # based on guard-shell by Joshua Hawxwell
  s.author       = "Adam Spiers"
  s.email        = "guard@adamspiers.org"
  s.summary      = "Guard gem for running sclang commands"
  s.homepage     = "http://github.com/aspiers/guard-sclang"
  s.license      = 'MIT'
  s.version      = Guard::SclangVersion::VERSION

  s.description  = <<-DESC
    Guard::Sclang automatically runs sclang commands when watched files are
    modified.
  DESC

  s.add_dependency 'guard', '~> 2.0', '>= 2.0.0'
  s.add_dependency 'guard-compat', '~> 1.0'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'guard-rspec', '~> 4.7'

  s.files        = %w(README.md CONTRIBUTING.md LICENSE unit-test-cli.scd)
  s.files       += Dir["{lib}/**/*"]
end
