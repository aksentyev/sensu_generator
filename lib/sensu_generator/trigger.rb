module SensuGenerator
  class Trigger
    attr_reader :last, :previous

    def initialize
      @previous = Time.now.to_f
      @last     = Time.now.to_f
    end

    def touch
      logger.info "Touch trigger!"
      @previous = @last
      @last = Time.now.to_f
    end

    def difference_between_touches
      @last - @previous
    end

    def last_touch_age
      Time.now.to_f - @last
    end

    def clear
      logger.info "Clear trigger!"
      time      = Time.now.to_f
      @previous = time
      @last     = time
    end

    def modified_since_last_update?
      @previous != @last
    end

    def logger
      @logger ||= Application.logger
    end
  end
end
