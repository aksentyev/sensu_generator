require 'ruby-supervisor'
require 'rsync'

module SensuGenerator
  class SensuServer
    attr_reader :address

    def initialize(address:, config:, logger: Application.logger)
      @address = address
      @config  = config
      @logger  = logger
    end

    def process
      unless @process
        client = RubySupervisor::Client.new(address, 9001,
            user: @config.get[:sensu][:supervisor][:user],
            password: @config.get[:sensu][:supervisor][:password]
          )
        @process = client.process('sensu-server')
      end
      @process
    end

    def restart
      process.restart
      @logger.info "Send restart command to sensu-server #{@address}"
      running?
    end

    def running?
      10.times do |t|
        if process.state.to_s == 'running'
          msg = "Sensu-server #{@address} was successfully restarted"
          @logger.info msg
          return true
        else
          if t == 10
            msg = "Sensu-server #{@address} restart FAILED"
            fail SensuServerError.new msg
          end
          sleep 1
        end
      end
    rescue SensuServerError => e
      @logger.error e
      false
    end

    def state
      process.state
    end

    def sync
      begin
        res = Rsync.run(result_dir, "rsync://#{@address}/sensu-checks", "--delete --recursive")
        status = res.success?
        if status
          msg = "synced"
          @logger.info ("Sensu-server #{@address}: #{msg}")
        else
          msg = "sync FAILED, out: #{res.inspect}"
          fail SensuServerError.new("Sensu-server #{@address}: #{msg}")
        end
      rescue SensuServerError => e
        @logger.error e
      end
      status || false
    end

    private

    def result_dir
      File.expand_path(@config.get[:result_dir])
    end
  end
end
