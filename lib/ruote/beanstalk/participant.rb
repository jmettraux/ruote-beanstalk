
require 'ruote/beanstalk/participant_proxy'


#
# The "Proxy" prefix is meant to indicate that the real action is happening
# on the other side [of Beanstalk], but some people might prefer simply
# writing "Ruote::Beanstalk::Participant".
#
class Ruote::Beanstalk::Participant < Ruote::Beanstalk::ParticipantProxy
end

