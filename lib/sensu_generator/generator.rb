require 'json'
require 'erb'
require 'fileutils'

module SensuGenerator
  class Generator
    def initialize(trigger:, services: [], config: Application.config, logger: Application.logger)
      @trigger  = trigger
      @services = services
      @config   = config
      @logger   = logger
    end

    attr_writer :services
    attr_accessor :logger, :config

    def generate!
      @processed_files = []
      @services.each do |svc|
        next unless svc.changed?
        svc.checks.each do |check|
          next if check.nil?
          begin
            if check.class == String
              templates_for(check).each do |src|
                file_name = "#{svc.name}-#{File.basename(src).gsub(/\.(?:.*)/, '.json')}"
                dest = File.join(result_dir, file_name)
                result = merge_with_default_parameters(
                            JSON(
                              process(template: src, namespace: binding),
                              symbolize_names: true
                            )
                          )
                          
                if result
                  write(dest, JSON.pretty_generate(result))
                  @trigger.touch
                  @processed_files << file_name
                end
              end
            else
              #TODO
              # Implement json parameters parsing
            end
          rescue => e
            logger.error e
            next
          end
        end
      end
      @processed_files
    end

    def flush_results
      FileUtils.rm(Dir.glob("#{result_dir}/*"))
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
      raise GeneratorError.new("Failed to process ERB file #{template}.\n #{e.to_s} \n#{e.backtrace}")
    end

    def templates_for(check)
      Dir.glob("#{File.expand_path(templates_dir)}/#{check}*")
    end

    def templates_dir
      config.get[:templates_dir]
    end

    def result_dir
      raise GeneratorError.new("Result dir is not defined!") unless config.get[:result_dir]
      File.expand_path(config.get[:result_dir])
    end

    def write(dest, data)
      file = File.open(dest, 'w+')
      file.write(data)
      file.close
    end
  end
end
