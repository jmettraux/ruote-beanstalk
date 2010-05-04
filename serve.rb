
$:.unshift('../ruote/lib')
$:.unshift('lib')

require 'fileutils'
FileUtils.rm_rf('ruote_work')

cpid = fork do
  exec "beanstalkd"
end

at_exit do
  Process.kill(9, cpid)
end

require 'ruote'
require 'ruote/beanstalk/storage'

Ruote::Beanstalk::BsStorage.new('127.0.0.1:11300', 'ruote_work')

