require 'json'
require 'erb'
require 'fileutils'

module SensuGenerator
  class Generator
    def initialize(trigger:, services: [], config:, logger: Application.logger)
      @trigger  = trigger
      @services = services
      @config   = config
      @logger   = logger
    end

    attr_writer :services

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

                file = File.open(dest, 'w+')
                file.write(result)
                file.close

                @trigger.touch if result
                @processed_files << file_name
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
    attr_reader :logger

    def merge_with_default_parameters(hash)
      {}.tap do |res|
        res[:checks] = {}
        hash[:checks].map do |k, v|
          res[:checks][k] = v.merge(@config.get[:sensu][:check_default_params])
        end
      end
    end

    def process(template:, namespace:)
      ERB.new(File.read(template)).result(namespace)
    rescue => e
      fail GeneratorError.new("Failed to process ERB file #{template}.\n #{e.backtrace}")
    rescue GeneratorError => e
      logger.warn e
    end

    def templates_for(check)
      list = Dir.glob("#{templates_dir}/#{check}*").map {|f| File.expand_path f}
      logger.debug "Templates for #{check}"
      list
    end

    def templates_dir
      @config.get[:templates_dir]
    end

    def result_dir
      fail GeneratorError.new("Result dir is not defined!") unless @config.get[:result_dir]
      File.expand_path(@config.get[:result_dir])
    end
  end
end
