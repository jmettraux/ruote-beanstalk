
# ruote-beanstalk

Beanstalk extensions for ruote 2.1 (a Ruby workflow engine).

"Beanstalk is a simple, fast workqueue service" (http://kr.github.com/beanstalkd/).

ruote-beanstalk provides a participant/receiver pair. Emitting workitems to a Beanstalk queue/tube and listening/receiving them back. Workers can connect to the Beanstalk queue, receive workitems, do some work and then (optionally) send the updated workitem back to the ruote system.

There is a bonus : Ruote::Beanstalk::BsStorage, a storage implementation for ruote. Workers and engines can connect over Beanstalk to a shared storage.

BsStorage listens to a Beanstalk queue where it receives storage orders that it conveys to a FsStorage instance.

(Initially I tried to use Beanstalk for msgs and schedules as well, but since you can't delete a delayed message in Beanstalk (as of now), I fell back to using Beanstalk as middleware, it's slightly slower, but much simpler and robust).

RDOC : http://ruote.rubyforge.org/ruote-beanstalk_rdoc/


## usage

### Ruote::Beanstalk::BsParticipant and BsReceiver

Registering a Beanstalk participant :

    @engine.register_participant(
      'alpha',
      Ruote::Beanstalk::BsParticipant,
      'beanstalk' => '127.0.0.1:11300',
      'tube' => 'ruote-workitems')


Binding a listener to a storage or an engine :

    Ruote::Beanstalk::BsReceiver.new(
      engine, '127.0.0.1:11300', 'tube' => 'ruote-incoming')

        # or

    Ruote::Beanstalk::BsReceiver.new(
      storage, '127.0.0.1:11300', 'tube' => 'ruote-incoming')

The receiver manages a thread that listens to incoming messages and feeds them to ruote via the engine or directly via a storage.


### Ruote::Beanstalk::BsStorage

There are two modes in which BsStorage can be used :

* bound to a remote storage (client)
* bound to the physical storage (server)

There should always be at least 1 server and 1 client.

<a href="http://github.com/jmettraux/ruote-beanstalk/raw/ruote2.1/doc/storages.png"><img src="http://github.com/jmettraux/ruote-beanstalk/raw/ruote2.1/doc/storages.png" /></a>

Beanstalk is the intermediary.


#### client

Pass a string of the form host:port and a hash of options :

    Ruote::Beanstalk::BsStorage.new('127.0.0.1:11300', opts)

Wrapped in an engine + worker :

    engine = Ruote::Engine.new(
      Ruote::Worker.new(
        Ruote::Beanstalk::BsStorage.new('127.0.0.1:11300', opts)))

#### server

This piece of ruby starts a Beanstalk instance (:fork => true) and starts a BsStorage 'server' coupled to an embedded FsStorage :

    require 'ruote/beanstalk'

    Ruote::Beanstalk::BsStorage.new(':11300', 'ruote_work', :fork => true)


## running tests

### Ruote::Beanstalk::BsParticipant and BsReceiver

Simply do

    ruby test/test.rb

in your ruote-beanstalk/ directory.


### Ruote::Beanstalk::BsStorage

assuming you have

    ruote/
    ruote-beanstalk/

In a separate terminal, go to ruote-beanstalk/ and launch

    ruby serve.rb

To launch a beanstalkd + fs storage couple, then run unit or functional tests


* unit tests :

get into ruote/ and do

    ruby test/unit/storage.rb --beanstalk

* functional tests :

get into ruote/ and do

    ruby test/functional/test.rb --beanstalk


## license

MIT


## links

* http://kr.github.com/beanstalkd/

* http://ruote.rubyforge.org/
* http://github.com/jmettraux/ruote-beanstalk


## feedback

mailing list : http://groups.google.com/group/openwferu-users
irc : irc.freenode.net #ruote


## many thanks to

- the beanstalk authors and contributors

