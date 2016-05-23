module SensuGenerator
  class Trigger < Application
    attr_reader :last, :previous

    def initialize
      @previous = Time.now.to_i
      @last     = Time.now.to_i
    end

    def touch
      logger.info "Touch trigger!"
      @previous = @last
      @last = Time.now.to_i
    end

    def difference_between_touches
      @last - @previous
    end

    def last_touch_age
      Time.now.to_i - @last
    end

    def clear
      @previous = 0
      @last     = 0
    end

    def modified_since_last_update?
      @previous != @last
    end
  end
end
