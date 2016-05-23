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
      logger.info "Starting application..."
    end

    def logger
      @@logger
    end

    def notifier
      @@notifier
    end

    def run_restarter
      logger.info "Starting restarter..."
      loop do
        logger.debug 'Restarter is alive!'
        if restarter.need_to_apply_new_configs?
          restarter.perform_restart
          trigger.reset
        end
        sleep 60
      end
    end

    def run_generator
      logger.info "Starting generator..."
      generator.flush_results
      loop do
        logger.debug 'Generator is alive!'
        if state.changed?
          generator.services = state.changes
          list = generator.generate!
          logger.info %Q(Files processed: #{list.join("\n")})
        end
        sleep 60
        state.actualize
      end
    rescue Diplomat::PathNotFound
      fail ApplicationError.new("Could not connect to #{config.get[:consul][:url]}")
    end

    def run
      %w(generator restarter).each do |thr|
        @threads << run_thread(thr)
      end

      loop do
        @threads.each do |thr|
          unless thr.alive?
            @threads.delete thr
            @threads << run_thread(thr.name)
          logger.error "#{thr.name.capitalize} is NOT ALIVE. Trying to restart."
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
      sensu_servers = consul.sensu_servers
      logger.info "Sensu servers discovered: #{sensu_servers.map(&:address).join(',')}"
      @restarter ||= Restarter.new(trigger: trigger, servers: sensu_servers, config: config)
    end

    def consul
      @consul ||= Consul.new(config: config)
    end

    def generator
      @generator ||= Generator.new(trigger: trigger, config: config)
    end

    def state
      @state ||= ConsulState.new(consul: consul)
    end

    def run_thread(name)
      thr = eval("Thread.new { run_#{name} }")
      thr.name = name
      thr
    end
  end
end
