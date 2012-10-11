

BS_PORT = (ENV['BS_PORT'] || 11307).to_i


module RuoteBeanstalkHelper

  def setup_beanstalk

    @bs_pid = Ruote::Beanstalk.fork(
      :address => '127.0.0.1',
      :port => BS_PORT,
      :no_kill_at_exit => true,
      :quiet => true)

    sleep 0.100
  end

  def teardown_beanstalk

    Process.kill(9, @bs_pid) if @bs_pid
  end

  def setup_ruote

    @engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))
    @engine.noisy = ENV['NOISY'] == 'true'
  end
end

