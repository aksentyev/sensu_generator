require 'thread'

module SensuGenerator
  class Application
    class << self
      def logger
        @@logger
      end

      def notifier
        @@notifier
      end
    end

    def initialize(config:, logger:, notifier:)
      @config  = config
      @threads = []
      @@logger = logger
      @@notifier = notifier
    end

    def logger
      @@logger
    end

    def notifier
      @@notifier
    end

    def run_restarter
      loop do
        if restarter.need_to_apply_new_configs?
          restarter.perform_restart
          trigger.reset
        end
        sleep 60
      end
    end

    def run_generator
      state = ConsulState.new(consul: consul)
      loop do
        require 'pry'
        binding.pry
        if state.actualize.changed?
          logger.info "Consul state was changed."
          generator.services = state.changes
          list = generator.generate!
          logger.info %Q(Files processed: #{list.join("\n")})
        end
        sleep 60
      end
    end

    def run
      require 'pry'
      binding.pry
      @threads << generator = Thread.new { run_generator }
      @threads << restarter = Thread.new { run_restarter }

      loop do
        @threads.each do |thr|
          unless thr.alive?
            @threads.delete thr
            @threads << eval("#{thr} = Thread.new { run_#{thr} }")
          logger.error "#{thr} is NOT ALIVE. Trying ot restart."
          end
        end
        sleep 60
      end
    end

    private
    def config
      @config
    end

    def trigger
      @trigger ||= Trigger.new
    end

    def restarter
      @restarter ||= Restarter.new(trigger: trigger, servers: consul.sensu_servers)
    end

    def consul
      @consul ||= Consul.new(config: config)
    end

    def generator
      @generator ||= Generator.new(trigger: trigger, config: config)
    end
  end
end
