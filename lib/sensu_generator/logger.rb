require 'logger'

module SensuGenerator
  class Logger < ::Logger
    def initialize(config)
      @config = config
      super(config[:file])
    end

    def level
      super(config[:log_level])
    end

    %i(debug info warn error fatal).each do |level|
      define_method(level) do |msg|
        if @config[:notify_level] == level
          Application.notifier.notify msg
        end
        super(msg)
      end
    end
  end
end
