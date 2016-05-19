#!/usr/bin/env ruby
require 'sensu_generator'
require 'optparse'
require 'daemons'

module SensuGenerator
  class << self
    def main
      config_file = nil#{config_file: 'sensu-generator.conf'}

      OptionParser.new do |opts|
        opts.banner = "sensu-generator [options]"

        opts.on("-c", "--config File", String, "Path to config file. Default: ./sensu-generator.conf") do |item|
          config_file = item
        end
        opts.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!

      config   = Config.new(config_file).config
      logger   = Logger.new(config[:logger])
      logger.level = eval("Logger::#{config[:logger][:log_level].upcase}")
      notifier = Notifier.new(config[:slack])

      Application.new(config: config, logger: logger, notifier: notifier).run
    rescue => exception
      msg = ("sensu-generator exited with non-zero code.\n #{exception.backtrace.join("\n\t")}")
      logger.fatal msg
    #   #TODO
    # #   notifier.notify msg
    end
  end
end

# if __FILE__ == $0
#   Daemons.run_proc(__FILE__) do
    SensuGenerator::main
  # end
# end
