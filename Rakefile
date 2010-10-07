
require 'rubygems'
require 'rake'

require 'lib/ruote/beanstalk/version.rb'

#
# CLEAN

require 'rake/clean'
CLEAN.include('pkg', 'tmp', 'html', 'rdoc')
task :default => [ :clean ]


#
# GEM

require 'jeweler'

Jeweler::Tasks.new do |gem|

  gem.version = Ruote::Beanstalk::VERSION
  gem.name = 'ruote-beanstalk'
  gem.summary = 'Beanstalk participant/receiver/storage for ruote (a Ruby workflow engine)'
  gem.description = %{
Beanstalk participant/receiver/storage for ruote (a Ruby workflow engine)
  }.strip
  gem.email = 'jmettraux@gmail.com'
  gem.homepage = 'http://github.com/jmettraux/ruote-beanstalk'
  gem.authors = [ 'John Mettraux' ]
  gem.rubyforge_project = 'ruote'

  gem.test_file = 'test/test.rb'

  gem.add_dependency 'ruote', ">= #{Ruote::Beanstalk::VERSION}"
  gem.add_dependency 'rufus-cloche', '>= 0.1.17'
  gem.add_dependency 'beanstalk-client', '>= 1.1.0'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'jeweler'

  # gemspec spec : http://www.rubygems.org/read/chapter/20
end
Jeweler::GemcutterTasks.new


#
# DOC

#
# make sure to have rdoc 2.5.x to run that
#
require 'rake/rdoctask'
Rake::RDocTask.new do |rd|

  rd.main = 'readme.rdoc'
  rd.rdoc_dir = 'rdoc/ruote-beanstalk_rdoc'
  rd.title = "ruote-beanstalk #{Ruote::Beanstalk::VERSION}"

  rd.rdoc_files.include(
    'readme.rdoc', 'CHANGELOG.txt', 'CREDITS.txt', 'lib/**/*.rb')
end


#
# TO THE WEB

task :upload_rdoc => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/ruote'

  sh "rsync -azv -e ssh rdoc/ruote-beanstalk_rdoc #{account}:#{webdir}/"
end

