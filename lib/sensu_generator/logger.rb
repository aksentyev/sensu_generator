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

    %w(debug info warn error fatal).each do |level|
      define_method(level) do |msg|
        begin
          if @params[:notify_level] == level
            Application.notifier.notify msg
          end
        rescue => e
          super(e)
        end
        super(msg)
      end
    end
  end
end
