require 'ruby-supervisor'
require 'rsync'

module SensuGenerator
  class Restarter
    attr_accessor :logger, :config

    def initialize(trigger:, servers:, logger: Application.logger, config: Application.config)
      @delay = 0
      @delay_inc = 600
      @config = config
      @trigger = trigger
      @servers = servers
      @logger = logger
    end

    def perform_restart
      servers_updated = []
      tries = 0

      @servers.each do |server|
        begin
          if @servers.size < config.get[:sensu][:minimal_to_restart]
            msg = "Sensu-servers count < #{config.get[:sensu][:minimal_to_restart]}. Restart will not be performed. Next try after #{@delay + @delay_inc}s."
            fail RestarterError.new(msg)
            @delay += @delay_inc if @delay < 3600
            sleep @delay
            break
          end

          server.sync &&
          server.restart &&
          servers_updated << server.address

          if servers_updated.size == @servers.size && @servers.index(server) == (@servers.size - 1)
            @trigger.clear
          else
            fail RestarterError.new("Could not synchronize or restart #{@servers - servers_updated.join(',')}")
          end
        rescue => e
          tries += 1
          tries <= 3 ? retry : next
        end
      end
    end

    def need_to_apply_new_configs?
      logger.debug "\n  Trigger:\n\tdifference_between_touches: #{@trigger.difference_between_touches}"\
                    "\n\tlast_touch_age: #{@trigger.last_touch_age}"\
                    "\n\tmodified_since_last_update?: #{@trigger.modified_since_last_update?}"
      (@trigger.difference_between_touches > 120 || @trigger.last_touch_age > 120) && @trigger.modified_since_last_update?
    end
  end
end
