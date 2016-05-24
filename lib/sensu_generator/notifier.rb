require 'slack-notifier'

module SensuGenerator
  class Notifier
    def initialize(params)
      @notifier = if !params.any? {|k,v| v == "" || v.nil?}
                    Slack::Notifier.new(params[:url], params[:channel])
                  end
    end

    def notify(msg)
      @notifier.ping msg if @notifier
    end
  end
end
