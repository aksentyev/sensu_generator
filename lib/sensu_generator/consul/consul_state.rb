module SensuGenerator
  class ConsulState < Consul
    def initialize
      @actual_state = []
      super()
      actualize
    end

    def show
      @actual_state
    end

    def actualize
      reset
      @svc_list_diff = services.map {|name, _| name.to_s } - @actual_state.map { |svc| svc.name.to_s}
      @actual_state.each(&:update)
      @svc_list_diff.each do |name|
        @actual_state << ConsulService.new(name: name)
      end
      @actualized = true
      logger.debug "Services actualized list: #{@actual_state.map { |svc| svc.name.to_s} }"
      self
    end

    def changed?
      state = !(@svc_list_diff || []).empty? || !changes.empty?
      logger.debug "Consul state was changed: #{state.to_s}"
      state
    end

    def changes
      @svc_changes ||= @actual_state.select(&:changed?)
    end

    def reset
      @actualized = false
      @svc_changes = nil
      @svc_list_diff = nil
    end

    def actualized?
      @actualized ? true : false # For the case when nil
    end
  end
end
