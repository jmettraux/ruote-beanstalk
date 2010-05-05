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
#require 'ruote/part/local_participant'


module Ruote
module Beanstalk

  class BsParticipant

    include Ruote::LocalParticipant

    def initialize (opts)

      @opts = opts
    end

    def consume (workitem)

      connection.put(encode_workitem(workitem))

      reply(workitem) if @opts['reply_by_default']
    end

    def cancel (fei, flavour)

      connection.put(encode_cancelitem(fei, flavour))
    end

    def encode_workitem (workitem)

      Rufus::Json.encode([ 'workitem', workitem.to_h ])
    end

    def encode_cancelitem (fei, flavour)

      Rufus::Json.encode([ 'cancelitem', fei.to_h, flavour.to_s ])
    end

    protected

    def connection

      con = ::Beanstalk::Connection.new(@opts['beanstalk'])

      if tube = @opts['tube']
        con.use(tube)
      end

      con
    end
  end
end
end

