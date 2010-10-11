require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "mongo_translatable"
    gem.summary = %Q{MongoDB backed Rails specific I18n model localization meant to tie-in to existing ActiveRecord models}
    gem.description = %Q{Rails specific I18n model localization meant to tie-in to existing ActiveRecord models, ala Globalize2, backed by MongoDB rather than an RDBMS. May include UI elements, too.}
    gem.email = "walter@katipo.co.nz"
    gem.homepage = "http://github.com/kete/mongo_translatable"
    gem.authors = ["Walter McGinnis"]
    gem.add_dependency "mongo_mapper", ">= 0.7.3"
    gem.add_dependency "activerecord", "2.3.5"
    gem.add_development_dependency "shoulda", ">= 2.10.3"
    gem.add_development_dependency "factory_girl", "= 1.2.3"
    gem.add_development_dependency "webrat", ">= 0.5.3"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  puts "This gem includes a full rails app for running tests (and staging development not yet extracted to the gem proper). Run tests there by changing to test/full_[RAIlS_VERSION_#_with_underscores]_app_with_tests and doing 'rake test'."
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongo_translatable #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
