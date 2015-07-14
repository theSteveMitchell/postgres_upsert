# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)


Gem::Specification.new do |s|
  s.name = "postgres_upsert"
  s.version = "5.0.0"

  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version     = ">= 1.8.7"
  s.authors = ["Steve Mitchell"]
  s.date = "2014-09-12"
  s.description = "Uses Postgres's powerful COPY command to upsert large sets of data into ActiveRecord tables"
  s.email = "thestevemitchell@gmail.com"
  git_files            = `git ls-files`.split("\n") rescue ''
  s.files              = git_files
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables        = []
  s.require_paths      = %w(lib)
  s.homepage = "https://github.com/theSteveMitchell/postgres_upsert"
  s.require_paths = ["lib"]
  s.summary = "A rubygem that integrates with ActiveRecord to insert/update large data sets into the database efficiently"

  s.add_dependency "pg", '>= 0.17.0'
  s.add_dependency "activerecord", '>= 3.0.0'
  s.add_dependency "rails", '>= 3.0.0'
  s.add_development_dependency "bundler"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "rspec", "~> 2.12"
  s.add_development_dependency "rspec-rails", "~> 2.0"
end

