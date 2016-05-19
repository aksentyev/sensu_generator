module SensuGenerator
  class ConsulState < Consul
    def initialize(consul:, logger: Application.logger)
      @logger = logger
      @consul = consul
      reset
      actualize
    end

    def show
      @actual_state
    end

    def actualize
      consul_services = @consul.services
      @svc_list_diff = consul_services.map {|name, _| name.to_s }.sort - @actual_state.map { |svc| svc.name.to_s}.sort
      @svc_list_diff.each do |name|
        @actual_state << ConsulService.new(consul: @consul, name: name)
      end
      logger.debug "Services actualized list: #{@actual_state}"
      self
    end

    def changed?
      state = !svc_list_diff.empty? && svc_changes
      logger.debug "Consul state was changed" if state
      state
    end

    def changes
      @svc_changes ||= @actual_state.map do |svc|
                        svc.update
                        svc.changed?
                        svc
                      end
    end

    def reset
      @actual_state = []
      @svc_changes = []
      @svc_list_diff = []
    end

    private

    attr_reader :logger
  end
end
