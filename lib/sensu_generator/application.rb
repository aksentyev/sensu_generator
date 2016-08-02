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

      def config
        @@config
      end

      def trigger
        @@trigger
      end
    end

    def initialize(config:, logger:, notifier:, trigger:)
      @@logger   = logger
      @@notifier = notifier
      @@config   = config
      @@trigger  = trigger
      @threads = []

      logger.info "Starting application #{VERSION}v..."
    end

    def logger
      @@logger
    end

    def notifier
      @@notifier
    end

    def config
      @@config
    end

    def trigger
      @@trigger
    end

    def run_restarter
      logger.info "Starting restarter..."
      loop do
        logger.info 'Restarter is alive!'
        if restarter.need_to_apply_new_configs?
          restarter.perform_restart
        end
        sleep 60
      end
    rescue => e
      raise ApplicationError.new("Restarter error:\n\t #{e.to_s}\n\t #{e.backtrace}")
    end

    def run_generator
      logger.info "Starting generator..."
      generator.flush_results
      state = ConsulState.new
      loop do
        logger.info 'Generator is alive!'
        if state.changed? && state.actualized?
          generator.services = state.changes
          list = generator.generate!
          logger.info %Q(#{list.size} files processed: #{list.join(', ')})
          if list.empty? && state.changes.any?{ |svc| svc.name == config.get[:sensu][:service] }
            logger.info "Sensu-server service state was changed"
            trigger.touch
          end
        end
        sleep 60
        state.actualize
      end
    rescue => e
      raise ApplicationError.new("Generator error:\n\t #{e.to_s}\n\t #{e.backtrace}")
    end

    def run_server
      server = Server.new
    rescue => e
      server&.close
      raise ApplicationError.new("Server error:\n\t #{e.to_s}\n\t #{e.backtrace}")
    end

    def run
      threads = %w(generator restarter)
      threads << 'server' if config.get[:mode] == 'server' && config.get[:server][:port]
      threads.each do |thr|
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

    def consul
      @consul ||= Consul.new
    end

    def generator
      @generator ||= Generator.new
    end

    def restarter
      list = consul.sensu_servers
      logger.info "Sensu servers discovered: #{list.map(&:address).join(', ')}"
      Restarter.new(list)
    end

    def run_thread(name)
      thr = eval("Thread.new { run_#{name} }")
      thr.name = name
      thr
    end
  end
end
