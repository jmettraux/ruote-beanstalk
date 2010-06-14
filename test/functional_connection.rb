
#
# testing ruote-beanstalk
#
# Mon May  3 19:00:00 JST 2010
#

require 'yajl' rescue require 'json'
require 'rufus-json'
Rufus::Json.detect_backend

require 'ruote/beanstalk'


def new_storage (opts)

  Ruote::Beanstalk::BsStorage.new('127.0.0.1:11300', opts)
end

