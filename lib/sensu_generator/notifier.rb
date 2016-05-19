require 'slack-notifier'

module SensuGenerator
  class Notifier
    def initialize(params)
      @notifier = Slack::Notifier.new(params[:url], params[:channel])
    end

    def notify(msg)
      @notifier.ping msg
    end
  end
end
