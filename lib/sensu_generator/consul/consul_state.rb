module SensuGenerator
  class ConsulState < Consul
    def initialize(consul: nil, logger: Application.logger)
      @logger = logger
      @consul = consul
      @actual_state = []

      actualize
    end

    def show
      @actual_state
    end

    def actualize
      reset
      @svc_list_diff = @consul.services.map {|name, _| name.to_s } - @actual_state.map { |svc| svc.name.to_s}
      @actual_state.each(&:update)
      @svc_list_diff.each do |name|
        @actual_state << ConsulService.new(consul: @consul, name: name)
      end
      logger.debug "Services actualized list: #{@actual_state.map { |svc| svc.name.to_s} }"
      self
    end

    def changed?
      state = !@svc_list_diff.empty? || !changes.empty?
      logger.debug "Consul state was changed: #{state.to_s}"
      state
    end

    def changes
      @svc_changes ||= @actual_state.select(&:changed?)
    end

    def reset
      @svc_changes = nil
      @svc_list_diff = nil
    end

    private

    attr_reader :logger

    def consul
      @consul ||= Consul.new
    end
  end
end
