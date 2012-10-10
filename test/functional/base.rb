
ruote_beanstalk_lib = File.expand_path(
  File.join(File.dirname(__FILE__), %w[ .. .. lib ]))

$:.unshift(ruote_beanstalk_lib)

require 'test/unit'

require 'yajl'

require 'ruote'
require 'ruote/beanstalk'


module BeanstalkTestSetup

  def setup

    port = 11300

    found = false
    socket = nil
    begin
      socket = TCPSocket.new('127.0.0.1', port)
      found = true
    rescue
    ensure
      socket.close if socket
    end

    unless found

      @bs_pid = Ruote::Beanstalk.fork(
        :address => '127.0.0.1',
        :port => port,
        :no_kill_at_exit => true,
        :quiet => true)

      sleep 0.100
    end

    @engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))
  end

  def teardown

    Process.kill(9, @bs_pid) if @bs_pid
  end
end

