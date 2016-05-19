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
      namespace = binding
      # flush_results
      @services.each do |svc|
        require 'pry'
        binding.pry
        if svc.properties.class == Array
          svc.properties.each do |instance|
            svc.checks.each do |check|
              next if check.nil?

              if check.class == String
                templates_for(check).each do |src|
                  file_name = "#{svc}-#{File.basename(src).gsub(/\.(?:.*)/, '.json')}"
                  dest = File.join(result_dir, file_name)
                  props = instance ? instance : svc
                  namespace.local_variable_set(:props, svc)
                  namespace.local_variable_set(:check, check)

                  result = process(template: src, namespace: namespace)
                  File.new(dest, 'w').write(result)

                  @trigger.touch if result
                  @processed_files << file_name
                end
                #TODO
                # Implement json parameters parsing
              end
            end
          end
        end
      end
      @processed_files
    end

    private
    attr_reader :logger

    def flush_results
      fail GeneratorError.new("Result dir is not defined!") unless result_dir
      FileUtils.rm(Dir.glob("#{result_dir}/*"))
    rescue GeneratorError => e
      logger.error e
    end

    def process(template:, namespace:)
      ERB.new(File.read(template)).result(namespace)
    rescue => e
      fail GeneratorError.new("Failed to process ERB file #{template}.\n #{e.backtrace}")
    rescue GeneratorError => e
      logger.warn e
    end

    def templates_for(check)
      list = File.expand_path Dir.glob("#{templates_dir}/#{check}*")
      logger.debug "Templates for #{check}"
      list
    end

    def templates_dir
      @config[:sensu][:templates_dir]
    end

    def result_dir
      File.expand_path(@config[:sensu][:result_dir])
    end
  end
end
