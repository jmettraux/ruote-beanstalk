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

#require 'ruote/part/local_participant'


module Ruote
module Beanstalk

  #
  # This participant emits workitems towards a beanstalk queue.
  #
  #   engine.register_participant(
  #     :heavy_labour,
  #     :reply_by_default => true, :beanstalk => '127.0.0.1:11300')
  #
  #
  # == workitem format
  #
  # Workitems are encoded in the format
  #
  #   [ 'workitem', workitem.to_h ]
  #
  # and then serialized as JSON strings.
  #
  #
  # == cancel items
  #
  # Like workitems, but the format is
  #
  #   [ 'cancelitem', fei.to_h, flavour.to_s ]
  #
  # where fei is the FlowExpressionId of the expression getting cancelled
  # (and whose workitems are to be retired) and flavour is either 'cancel' or
  # 'kill'.
  #
  #
  # == extending this participant
  #
  # Extend and overwrite encode_workitem and encode_cancelitem or
  # simply re-open the class and change those methods.
  #
  #
  # == :beanstalk
  #
  # Indicates which beanstalk to talk to
  #
  #   engine.register_participant(
  #     'alice'
  #     Ruote::Beanstalk::ParticipantProxy,
  #     'beanstalk' => '127.0.0.1:11300')
  #
  #
  # == :tube
  #
  # Most of the time, you want the workitems (or the cancelitems) to be
  # emitted over/in a specific tube
  #
  #   engine.register_participant(
  #     'alice'
  #     Ruote::Beanstalk::ParticipantProxy,
  #     'beanstalk' => '127.0.0.1:11300',
  #     'tube' => 'ruote-workitems')
  #
  #
  # == :forget (or :reply_by_default)
  #
  # If the participant is configured with 'forget' => true, the
  # participant will dispatch the workitem over to Beanstalk and then
  # immediately reply to its ruote engine (letting the flow resume).
  #
  #   engine.register_participant(
  #     'alice'
  #     Ruote::Beanstalk::ParticipantProxy,
  #     'beanstalk' => '127.0.0.1:11300',
  #     'forget' => true)
  #
  class ParticipantProxy
    include Ruote::LocalParticipant

    def initialize(opts)

      @opts = opts
    end

    def on_workitem

      put(encode_workitem(workitem))

      reply if @opts['reply_by_default'] || @opts['forget']
    end

    def on_cancel

      put(encode_cancelitem(fei, flavour))
    end

    def encode_workitem(workitem)

      Rufus::Json.encode([ 'workitem', workitem.to_h ])
    end

    def encode_cancelitem(fei, flavour)

      Rufus::Json.encode([ 'cancelitem', fei.to_h, flavour.to_s ])
    end

    protected

    def put(message)

      con = ::Beanstalk::Connection.new(@opts['beanstalk'])

      if tube = @opts['tube']
        con.use(tube)
      end

      con.put(message)

    ensure
      con.close rescue nil
    end
  end
end
end

