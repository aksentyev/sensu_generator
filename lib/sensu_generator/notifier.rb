require 'slack-notifier'

module SensuGenerator
  class Notifier
    def initialize(params = {})
      @notifier = if !params.any? {|k,v| v == "" || v.nil?}
                    Slack::Notifier.new(params[:url], channel: params[:channel])
                  end
    end

    def notify(msg)
      @notifier.ping msg.to_s if @notifier
    end
  end
end
