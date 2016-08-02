require 'json'
require 'socket'

module SensuGenerator
  class Client
    def initialize
      @logger = Application.logger
      connect
    end

    attr_reader :config, :logger

    def connection
      @connection ||= connect
    end

    def connect
      logger.info "Client: connecting to server #{server_addr}:#{server_port}"
      s = TCPSocket.new(server_addr, server_port)
      logger.info "Client: connected"
      s
    rescue => e
      raise ClientError.new "Client: connection failed #{e.inspect} #{e.backtrace}\n"
    end

    def write_file(data)
      connection.puts data
    rescue => e
      logger.error "Client: write failed #{e.inspect} #{e.backtrace}\n"
      close
      sleep 1
      retry
    end

    def flush_results
      connection.puts JSON.fast_generate({"FLUSH_WITH_PREFIX" => "#{config.file_prefix}" })
    rescue => e
      logger.error "Client: write failed #{e.inspect} #{e.backtrace}\n"
      close
      sleep 1
      retry
    end

    def close
      @connection.close
      @connection = nil
      logger.info "Client: connection closed"
    end

    private

    def config
      Application.config
    end

    def server_addr
      @server_addr ||= config.get[:server][:addr]
    end

    def server_port
      @server_port ||= config.get[:server][:port]
    end
  end
end
