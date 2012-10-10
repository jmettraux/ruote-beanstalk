# encoding: UTF-8

#
# testing ruote-beanstalk
#
# Mon Jun 14 19:43:57 JST 2010
#

require File.expand_path('../base', __FILE__)


class FtReceiverTest < Test::Unit::TestCase
  include BeanstalkTestSetup

  class HelloServer

    def initialize(port, tube_in, tube_out)

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
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => '127.0.0.1:11300',
      'tube' => 'in')

    Ruote::Beanstalk::Receiver.new(
      @engine, '127.0.0.1:11300', :tube => 'out')

    echo = HelloServer.new(11300, 'in', 'out')

    #@engine.context.logger.noisy = true

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    r = @engine.wait_for(wfid)

    assert_equal 'world', r['workitem']['fields']['hello']
  end

  def test_launchitem

    sp = @engine.register_participant '.+', Ruote::StorageParticipant

    Ruote::Beanstalk::Receiver.new(
      @engine, '127.0.0.1:11300', :tube => 'launch')

    #@engine.context.logger.noisy = true

    pdef = Ruote.process_definition do
      alpha
    end

    #fields = { 'hello' => '上海' }
    fields = { 'hello' => 'shangai' }

    launchitem = [ 'launchitem', [ pdef, fields, {} ] ]

    con = ::Beanstalk::Connection.new('127.0.0.1:11300')
    con.use('launch')
    con.put(Rufus::Json.encode(launchitem))

    sleep 1

    assert_equal 1, sp.size
    assert_equal 'alpha', sp.first.participant_name
    #assert_equal '上海', sp.first.fields['hello']
    assert_equal 'shangai', sp.first.fields['hello']
  end
end

