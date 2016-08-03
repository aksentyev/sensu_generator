require 'json'
require 'erb'
require 'fileutils'

module SensuGenerator
  class Generator
    def initialize(services = [])
      @services = services
      @config  = Application.config
      @trigger = Application.trigger
      @logger  = Application.logger
    end

    attr_writer :services
    attr_accessor :logger, :config
    attr_reader :connection

    def generate!
      @processed_files = []
      @services.each do |svc|
        next unless svc.changed?
        svc.checks.each do |check|
          next if check.nil?
          begin
            if check.class == String
              templates_for(check).each do |src|
                filename = config.file_prefix + "#{svc.name}-#{File.basename(src).gsub(/\.(?:.*)/, '.json')}"
                result = merge_with_default_parameters(
                            JSON.parse(
                              process(template: src, namespace: binding),
                              symbolize_names: true
                            )
                          )

                if result
                  write(filename: filename, data: result)
                  @processed_files << filename
                end
              end
            else
              #TODO
              # Implement json parameters parsing
            end
          rescue => e
            logger.warn e
            next
          end
        end
      end
      @processed_files
    end

    def flush_results
      CheckFile.remove_all_with(config.file_prefix)
    end

    private

    def merge_with_default_parameters(hash)
      {}.tap do |res|
        res[:checks] = {}
        hash[:checks].map do |k, v|
          res[:checks][k] = v.merge(config.get[:sensu][:check_default_params])
        end
      end
    end

    def process(template:, namespace:)
      logger.debug "Processing template #{template}"
      ERB.new(File.read(template)).result(namespace)
    rescue ::Exception => e # Catch all ERB errors
      raise GeneratorError.new "Failed to process ERB file #{template}.\n #{e.to_s} \n#{e.backtrace}"
    end

    def templates_for(check)
      Dir.glob("#{File.expand_path(templates_dir)}/#{check}*")
    end

    def templates_dir
      config.get[:templates_dir]
    end

    def write(filename:, data:)
      if config.get[:mode] == 'server'
        CheckFile.new(filename).write(JSON.pretty_generate(data))
      else
        json = JSON.fast_generate({ :filename => filename, :data => data })
        cl = Client.new
        cl.write_file(json)
        cl.close
      end
    rescue
      sleep 1
      retry
    end
  end
end
