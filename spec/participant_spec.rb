
require 'spec_helper'


describe Ruote::Beanstalk::Participant do

  before(:each) do
    setup_beanstalk
    setup_ruote
  end
  after(:each) do
    teardown_beanstalk
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

  it 'transmits workitems over beanstalk' do

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => '127.0.0.1:11300')

    watcher = Watcher.new(11300)

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for('dispatched')

    watcher.jobs.size.should == 1
    watcher.jobs.first.first.should == 'workitem'
  end

  it 'accepts a tube name when registered' do

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => '127.0.0.1:11300',
      'tube' => 'underground')

    watcher0 = Watcher.new(11300)
    watcher1 = Watcher.new(11300, 'underground')

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for('dispatched')

    watcher0.jobs.size.should == 0
    watcher1.jobs.size.should == 1
    watcher1.jobs.first.first.should == 'workitem'
  end
end

