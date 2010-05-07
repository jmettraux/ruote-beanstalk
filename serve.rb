
$:.unshift('../ruote/lib')
$:.unshift('lib')

require 'fileutils'
FileUtils.rm_rf('ruote_work')

require 'ruote/beanstalk'

Ruote::Beanstalk::BsStorage.new(':11300', 'ruote_work', :fork => true)

