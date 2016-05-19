require 'ruby-supervisor'
require 'rsync'

module SensuGenerator
  class Restarter
    @delay = 0
    @delay_inc = 600

    def initialize(logger: Application.logger, trigger:, servers:)
      @trigger = trigger
      @servers = servers
      @logger = logger
    end

    def perform_restart
      servers_updated = []
      tries = 0

      @servers.each do |server|
        begin
          if @servers.size < 2
            msg = "Sensu-servers count < 2. Restart will not be performed. Next try after #{@@delay + @@delay_inc}s."
            fail RestarterError.new(msg)
            @delay += @delay_inc if @delay < 3600
            sleep @delay
            break
          end

          # NOTE:
          # TBD:
          if server.address.include?('172.')
            fail RestarterError.new("Skipping node #{server.address}")
          end

          if need_update?
            server.sync &&
            server.restart &&
            servers_updated += server.address
          end

          if servers_updated.size == @servers.size && @servers.index(server) == @server.size
            actualize_update_time
          else
            fail RestarterError.new("Could not synchronize or restart #{@servers - servers_updated.join(',')}")
          end
        rescue => e
          tries += 1
          if tries <= 3
            retry
          else
            logger.error e
            next
          end
        end
      end
    end

    private

    def need_to_apply_new_configs?
      (@trigger.difference_between_touches > 120 || @trigger.last_touch_age > 120) && @trigger.modified_since_last_update?
    end
  end
end
