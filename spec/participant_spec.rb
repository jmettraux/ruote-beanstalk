
require 'spec_helper'


describe Ruote::Beanstalk::Participant do
  # or Ruote::Beansstalk::ParticipantProxy

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
        rescue EOFError => e
          #p e
          # just exit when the the beanstalk dies
        end
      end
    end
  end

  it 'transmits workitems over beanstalk' do

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::ParticipantProxy,
      'beanstalk' => "127.0.0.1:#{BS_PORT}")

    watcher = Watcher.new(BS_PORT)

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
      'beanstalk' => "127.0.0.1:#{BS_PORT}",
      'tube' => 'underground')

    watcher0 = Watcher.new(BS_PORT)
    watcher1 = Watcher.new(BS_PORT, 'underground')

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for('dispatched')

    watcher0.jobs.size.should == 0
    watcher1.jobs.size.should == 1
    watcher1.jobs.first.first.should == 'workitem'
  end

  it 'replies immediately when forget is set to true' do

    @engine.register_participant(
      :alpha,
      Ruote::Beanstalk::Participant,
      'beanstalk' => "127.0.0.1:#{BS_PORT}",
      'forget' => true)

    watcher = Watcher.new(BS_PORT)

    wfid = @engine.launch(Ruote.define do
      alpha
    end)

    @engine.wait_for('terminated')

    watcher.jobs.size.should == 1
    watcher.jobs.first.first.should == 'workitem'
  end
end

