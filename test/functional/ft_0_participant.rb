
#
# testing ruote-beanstalk
#
# Mon Jun 14 16:11:02 JST 2010
#

require File.expand_path('../base', __FILE__)


class FtParticipantTest < Test::Unit::TestCase

  def setup

    @bs_pid = Ruote::Beanstalk.fork(
      :address => '127.0.0.1',
      :port => 11300,
      :no_kill_at_exit => true,
      :quiet => true)

    sleep 0.100

    @engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))
  end

  def teardown

    Process.kill(9, @bs_pid) if @bs_pid
  end

  class Watcher

    attr_reader :jobs

    def initialize(port, tube=nil)

      @connection = ::Beanstalk::Connection.new("127.0.0.1:#{port}", tube)

      @jobs = []

      @thread = Thread.new do
        begin
          loop do
            job = @connection.reserve
            job.delete
            @jobs << Rufus::Json.decode(job.body)
          end
        rescue Exception => e
          #p e
        end
      end
    end
  end

  def test_participant

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => '127.0.0.1:11300')

    watcher = Watcher.new(11300)

    #@engine.context.logger.noisy = true

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for(:alpha)
    sleep 0.100

    assert_equal 1, watcher.jobs.size
    assert_equal 'workitem', watcher.jobs.first.first
  end

  def test_participant_tube

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => '127.0.0.1:11300',
      'tube' => 'underground')

    watcher0 = Watcher.new(11300)
    watcher1 = Watcher.new(11300, 'underground')

    #@engine.context.logger.noisy = true

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for(:alpha)
    sleep 0.100

    assert_equal 0, watcher0.jobs.size
    assert_equal 1, watcher1.jobs.size
    assert_equal 'workitem', watcher1.jobs.first.first
  end
end

