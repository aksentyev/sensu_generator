require 'logger'

module SensuGenerator
  class Logger < ::Logger
    def initialize(params)
      @params = params
      super(@params[:file])
    end

    def level
      super(@params[:log_level])
    end

    %i(debug info warn error fatal).each do |level|
      define_method(level) do |msg|
        if @params[:notify_level] == level
          Application.notifier.notify msg
        end
        super(msg)
      end
    end
  end
end
