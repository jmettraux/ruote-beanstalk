#--
# Copyright (c) 2005-2012, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'beanstalk-client'

#require 'ruote/receiver/base'


module Ruote
module Beanstalk

  #
  # An error class for error emitted by the "remote side" and received here.
  #
  class ReceiveError < RuntimeError

    attr_reader :fei

    def initialize(fei)
      @fei = fei
      super("for #{Ruote::FlowExpressionId.to_storage_id(fei)}")
    end
  end

  #
  # Whereas ParticipantProxy emits workitems(and cancelitems) to a Beanstalk
  # queue, the receiver watches a Beanstalk queue/tube.
  #
  # An example initialization :
  #
  #   Ruote::Beanstalk::Receiver.new(
  #     engine, '127.0.0.1:11300', :tube => 'out')
  #
  #
  # == workitem format
  #
  # ParticipantProxy and Receiver share the same format :3
  #
  #   [ 'workitem', workitem_as_a_hash ]
  #     # or
  #   [ 'error', error_details_as_a_string ]
  #
  #
  # == extending this receiver
  #
  # Feel free to extend this class and override the listen or the process
  # method.
  #
  #
  # == :tube
  #
  # Indicates to the receiver which beanstalk tube it should listen to.
  #
  #   Ruote::Beanstalk::Receiver.new(
  #     engine, '127.0.0.1:11300', :tube => 'out')
  #
  class Receiver < ::Ruote::Receiver

    # cwes = context, worker, engine or storage
    #
    def initialize(cwes, beanstalk, options={})

      super(cwes, options)

      Thread.new do
        listen(beanstalk, options['tube'] || options[:tube] || 'default')
      end
    end

    protected

    def listen(beanstalk, tube)

      con = ::Beanstalk::Connection.new(beanstalk)
      con.watch(tube)
      con.ignore('default') unless tube == 'default'

      loop do

        job = con.reserve
        job.delete
        process(job)
      end

    rescue EOFError => ee
      # over
    end

    # Is meant to return a hash with a first element that is either
    # 'workitem', 'error' or 'launchitem'(a type).
    # The second element depends on the type.
    # It's mappend on Ruote::Beanstalk::ParticipantProxy anyway.
    #
    def decode(job)

      Rufus::Json.decode(job.body)
    end

    def process(job)

      type, data = decode(job)

      if type == 'workitem'

        # data holds a workitem(as a Hash)

        reply(data)

      elsif type == 'error'

        # data holds a fei(FlowExpressionId) (as a Hash)

        @context.error_handler.action_handle(
          'dispatch', data, ReceiveError.new(data))

      elsif type == 'launchitem'

        pdef, fields, variables = data

        launch(pdef, fields, variables)

      #else simply drop
      end
    end
  end
end
end

