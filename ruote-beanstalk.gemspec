# encoding: utf-8

Gem::Specification.new do |s|

  s.name = 'ruote-beanstalk'
  s.version = File.read('lib/ruote/beanstalk/version.rb').match(/VERSION = '([^']+)'/)[1]
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://ruote.rubyforge.org'
  s.rubyforge_project = 'ruote'
  s.summary = 'Beanstalk participant/receiver/storage for ruote (a Ruby workflow engine)'
  s.description = %q{
Beanstalk participant/receiver/storage for ruote (a Ruby workflow engine)
}

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_runtime_dependency 'beanstalk-client', '1.1.0'
  s.add_runtime_dependency 'ruote', ">= #{s.version}"

  s.add_development_dependency 'rake'

  s.require_path = 'lib'
end

