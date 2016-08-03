require 'ruby-supervisor'
require 'rsync'

module SensuGenerator
  class Restarter
    attr_accessor :logger, :config

    def initialize(servers)
      @delay = 0
      @delay_inc = 600
      @config  = Application.config
      @trigger = Application.trigger
      @logger  = Application.logger
      @servers = servers
    end

    def perform_restart
      servers_updated = []

      @servers.each do |server|
        begin
          if @servers.size < config.get[:sensu][:minimal_to_restart]
            msg = "Sensu-servers count < #{config.get[:sensu][:minimal_to_restart]}. Restart will not be performed. Next try after #{@delay + @delay_inc}s."
            raise RestarterError.new(msg)
            @delay += @delay_inc if @delay < 3600
            sleep @delay
            break
          end

          server.sync &&
          server.restart &&
          servers_updated << server.address

          if server == @servers.last
            if servers_updated.size == @servers.size
              @trigger.clear
            else
              raise RestarterError.new("Could not synchronize or restart #{(@servers.map(&:address) - servers_updated).join(',')}")
            end
          end
        rescue => e
          logger.error "Restarter error: #{e.inspect} #{e.backtrace}"
          next
        end
      end
    end

    def need_to_apply_new_configs?
      result = (@trigger.difference_between_touches > 120 || @trigger.last_touch_age > 120) && @trigger.modified_since_last_update?
      logger.debug "\n  Trigger:\n\tdifference_between_touches: #{@trigger.difference_between_touches}"\
                    "\n\tlast_touch_age: #{@trigger.last_touch_age}"\
                    "\n\tmodified_since_last_update?: #{@trigger.modified_since_last_update?}"\
                    "\n\tNeeds to apply configuration to Sensu? #{result}"
      result
    end
  end
end
