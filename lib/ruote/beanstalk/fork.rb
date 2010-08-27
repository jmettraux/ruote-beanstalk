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


module Ruote
module Beanstalk

  OPT_KEYS = { :address => 'l', :port => 'p', :binlog => 'b', :user => 'u' }

  # :address
  # :port
  # :binlog
  # :user
  #
  def self.fork(opts={})

    quiet = opts.delete(:quiet)
    no_kill = opts.delete(:no_kill_at_exit)

    opts = opts.inject([]) { |a, (k, v)| a << "-#{OPT_KEYS[k]} #{v}" }.join(' ')

    cpid = Process.fork do
      puts "beanstalkd #{opts}" unless quiet
      exec "beanstalkd #{opts}"
    end

    unless no_kill
      at_exit { Process.kill(9, cpid) }
    end

    cpid
  end
end
end

