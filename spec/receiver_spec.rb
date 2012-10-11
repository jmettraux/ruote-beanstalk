
require 'spec_helper'


describe Ruote::Beanstalk::Receiver do

  before(:each) do
    setup_beanstalk
    setup_ruote
  end
  after(:each) do
    teardown_beanstalk
  end

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

  it 'receives workitem coming back from a participant' do

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => '127.0.0.1:11300',
      'tube' => 'in')

    Ruote::Beanstalk::Receiver.new(
      @engine, '127.0.0.1:11300', :tube => 'out')

    echo = HelloServer.new(11300, 'in', 'out')

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    r = @engine.wait_for(wfid)

    r['workitem']['fields']['hello'].should == 'world'
  end

  it 'accepts launchitems' do

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

    sp.size.should == 1
    sp.first.participant_name.should == 'alpha'
    #sp.first.fields['hello'].should == '上海'
    sp.first.fields['hello'].should == 'shangai'
  end
end

