#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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

require 'ruote'
#require 'ruote/receiver/base'


module Ruote
module Beanstalk

  class BsReceiveError < RuntimeError

    attr_reader :fei

    def initialize (fei)
      @fei = fei
      super("for #{Ruote::FlowExpressionId.to_storage_id(fei)}")
    end
  end

  class BsReceiver < Ruote::Receiver

    def initialize (cwes, beanstalk, tube, options={})

      super(cwes, options)

      Thread.new { listen(beanstalk, tube) }
    end

    def listen (beanstalk, tube)

      con = ::Beanstalk::Connection.new(beanstalk)
      con.watch(tube)
      con.ignore('default')

      loop do

        job = con.reserve
        job.delete

        process(job)
      end
    end

    def process (job)

      type, data = Rufus::Json.decode(job.body)

      if type == 'workitem'

        # data holds a workitem (as a Hash)

        reply(data)

      elsif type == 'error'

        # data holds a fei (FlowExpressionId) (as a Hash)

        @context.error_handler.action_handle(
          'dispatch', data, BsReceiveError.new(data))

      #else simply drop
      end
    end
  end
end
end

