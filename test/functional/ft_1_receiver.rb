
#
# testing ruote-beanstalk
#
# Mon Jun 14 19:43:57 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


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

  class HelloServer

    def initialize (port, tube_in, tube_out)

      @connection = ::Beanstalk::Connection.new("127.0.0.1:#{port}", tube_in)

      @thread = Thread.new do
        begin
          loop do

            job = @connection.reserve
            job.delete

            payload = Rufus::Json.decode(job.body)
            payload.last['fields']['hello'] = 'world'

            @connection.use(tube_out)
            @connection.put(Rufus::Json.encode(payload))
          end
        rescue Exception => e
          #p e
        end
      end
    end
  end

  def test_participant_and_receiver

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::BsParticipant,
      'beanstalk' => '127.0.0.1:11300',
      'tube' => 'in')

    Ruote::Beanstalk::BsReceiver.new(
      @engine, '127.0.0.1:11300', :tube => 'out')

    echo = HelloServer.new(11300, 'in', 'out')

    #@engine.context.logger.noisy = true

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    r = @engine.wait_for(wfid)

    assert_equal 'world', r['workitem']['fields']['hello']
  end
end

