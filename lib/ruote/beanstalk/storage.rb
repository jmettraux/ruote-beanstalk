#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
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

require 'fileutils'
require 'beanstalk-client'
#require 'ruote/storage/base'


module Ruote
module Beanstalk

  #
  # An error class just for BsStorage.
  #
  class StorageError < RuntimeError
  end

  #
  # This ruote storage can be used in two modes : client and server.
  #
  # Beanstalk is the medium.
  #
  # == client
  #
  # The storage is pointed at a beanstalk queue
  #
  #   engine = Ruote::Engine.new(
  #     Ruote::Worker.new(
  #       Ruote::Beanstalk::Storage.new('127.0.0.1:11300', opts)))
  #
  # All the operations(put, get, get_many, ...) of the storage are done
  # by a server, connected to the same beanstalk queue.
  #
  # == server
  #
  # The storage point to a beanstalk queue and receives orders from clients
  # via the queue.
  #
  #   Ruote::Beanstalk::Storage.new(':11300', 'ruote_work', :fork => true)
  #
  # Note the directory passed as a string. When in server mode, this storage
  # uses an embedded Ruote::FsStorage for the actual storage.
  #
  # The :fork => true lets the storage start and adjacent OS process containing
  # the Beanstalk server. The storage takes care of stopping the beanstalk
  # server when the Ruby process exits.
  #
  class Storage

    include Ruote::StorageBase

    def initialize(uri, directory=nil, options=nil)

      @uri, address, port = split_uri(uri)

      directory, @options = if directory.nil?
        [ nil, {} ]
      elsif directory.is_a?(Hash)
        [ nil, directory ]
      else
        [ directory, options || {} ]
      end

      @cloche = nil

      if directory
        #
        # run embedded Ruote::FsStorage

        require 'rufus/cloche'

        FileUtils.mkdir_p(directory)

        @cloche = Rufus::Cloche.new(
          :dir => directory, :nolock => @options['cloche_nolock'])
      end

      if fork_opts = @options[:fork]
        #
        # run beanstalk in a forked process

        fork_opts = fork_opts.is_a?(Hash) ? fork_opts : {}
        fork_opts = { :address => address, :port => port }.merge(fork_opts)

        Ruote::Beanstalk.fork(fork_opts)

        sleep 0.1
      end

      replace_engine_configuration(@options)

      serve if @cloche
    end

    # One catch : will return [] in case of [network] error
    #
    def get_msgs

      super rescue []
    end

    # One catch : will return true (failure) in case of [network] error
    #
    def reserve(doc)

      super(doc) rescue true
    end

    def put(doc, opts={})

      doc.merge!('put_at' => Ruote.now_to_utc_s)

      return @cloche.put(doc, opts) if @cloche

      r = operate('put', [ doc ])

      return r unless r.nil?

      doc['_rev'] = (doc['_rev'] || -1) + 1 if opts[:update_rev]

      nil
    end

    def get(type, key)

      return @cloche.get(type, key) if @cloche

      operate('get', [ type, key ])
    end

    def delete(doc)

      return @cloche.delete(doc) if @cloche

      operate('delete', [ doc ])
    end

    def get_many(type, key=nil, opts={})

      return operate('get_many', [ type, key, opts ]) unless @cloche

      if key
        key = Array(key).collect { |k|
          k[0..6] == '(?-mix:' ? Regexp.new(k[7..-2]) : "!#{k}"
        } if key
      end
        # assuming /!#{wfid}$/...

      @cloche.get_many(type, key, opts)
    end

    def ids(type)

      return @cloche.ids(type) if @cloche

      operate('ids', [ type ])
    end

    def purge!

      if @cloche
        FileUtils.rm_rf(@cloche.dir)
      else
        operate('purge!', [])
      end
    end

    def dump(type)

      get_many(type)
    end

    def shutdown

      Thread.list.each do |t|
        t.keys.each do |k|
          next unless k.to_s.match(CONN_KEY)
          t[k].close
          t[k] = nil
        end
      end
    end

    def close

      shutdown
    end

    # Mainly used by ruote's test/unit/ut_17_storage.rb
    #
    def add_type(type)

      # nothing to do
    end

    # Nukes a db type and reputs it(losing all the documents that were in it).
    #
    def purge_type!(type)

      if @cloche
        @cloche.purge_type!(type)
      else
        operate('purge_type!', [ type ])
      end
    end

    protected

    CONN_KEY = 'ruote-beanstalk-connection'
    TUBE_NAME = 'ruote-storage-commands'

    def split_uri(uri)

      uri = ':' if uri == ''

      address, port = uri.split(':')
      address = '127.0.0.1' if address.strip == ''
      port = 11300 if port.strip == ''

      [ "#{address}:#{port}", address, port ]
    end

    def connection

      c = Thread.current[CONN_KEY]

      #begin
      #  c.stats
      #  return c
      #rescue Exception => e
      #  c = nil
      #end if c
        # keeping around the idea around

      return c if c

      c = ::Beanstalk::Connection.new(@uri, TUBE_NAME)
      c.ignore('default')

      Thread.current[CONN_KEY] = c
    end

    def operate(command, params)

      client_id = "BsStorage-#{Thread.current.object_id}-#{$$}"
      timestamp = Time.now.to_f.to_s

      con = connection

      con.put(Rufus::Json.encode([ command, params, client_id, timestamp ]))

      con.watch(client_id)
      con.ignore(TUBE_NAME)

      result = nil

      loop do

        job = nil
        begin
          job = con.reserve
        rescue Exception => e
          # probably our timeout
          break
        end
        job.delete

        result, ts = Rufus::Json.decode(job.body)

        break if ts == timestamp # hopefully
      end

      if result.is_a?(Array) && result.first == 'error'
        raise ArgumentError.new(result.last) if result[1] == 'ArgumentError'
        raise StorageError.new(result.last)
      end

      result
    end

    COMMANDS = %w[ put get get_many delete ids purge! purge_type! dump ]

    def serve

      con = connection

      loop do

        job = con.reserve
        job.delete

        command, params, client_id, timestamp = Rufus::Json.decode(job.body)

        result = begin

          if COMMANDS.include?(command)
            send(command, *params)
          else
            [ 'error', 'UnknownCommand', command ]
          end

        rescue Exception => e
          #p e
          #e.backtrace.each { |l| puts l }
          [ 'error', e.class.to_s, e.to_s ]
        end

        con.use(client_id)
        con.put(Rufus::Json.encode([ result, timestamp ]))
      end
    end
  end
end
end

