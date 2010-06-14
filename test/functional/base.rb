
ruote_lib = File.expand_path(
  File.join(File.dirname(__FILE__), %w[ .. .. .. ruote lib ]))
ruote_beanstalk_lib = File.expand_path(
  File.join(File.dirname(__FILE__), %w[ .. .. lib ]))

$:.unshift(ruote_lib)
$:.unshift(ruote_beanstalk_lib)

require 'test/unit'

require 'rubygems'
require 'yajl'

require 'ruote'
require 'ruote/beanstalk'

