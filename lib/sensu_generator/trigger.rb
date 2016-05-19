module SensuGenerator
  class Trigger
    attr_reader :last, :previous

    def initialize
      @last = touch
    end

    def touch
      @last = Time.now.to_i
      @previous = @last
    end

    def difference_between_touches
      @last - @previous
    end

    def last_touch_age
      Time.now.to_i - @last
    end

    def clear
      @previous = @last
    end

    def modified_since_last_update?
      @previous != @last
    end
  end
end
