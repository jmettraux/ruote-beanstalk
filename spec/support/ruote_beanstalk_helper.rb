
module RuoteBeanstalkHelper

  def setup_beanstalk

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
  end

  def teardown_beanstalk

    Process.kill(9, @bs_pid) if @bs_pid
  end

  def setup_ruote

    @engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))
    @engine.noisy = ENV['NOISY'] == 'true'
  end
end

