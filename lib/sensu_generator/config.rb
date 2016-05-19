require 'json'

module SensuGenerator
  class Config
    attr_reader :config

    @@default = {
                :sensu => {
                  :check_default_params => {
                    :refresh => 86400,
                    :interval => 60,
                    :aggregate => true
                  },
                  :service => "sensu-server",
                  :supervisor => {:user => "", :password => ""},
                  :results_dir => "work"
                },
                :logger => {
                  :file => STDOUT,
                  :notify_level => "error",
                  :log_level => "debug"
                },
                :templates_dir => "tmp/templates",
                :result_dir => "tmp/result",
                :slack => {
                  :url => nil,
                  :channel => nil,
                  :level => "error"
                },
                # See diplomat documentation to set proper consul parameters
                :consul => {
                  :url => "http://consul.service.consul:8500"
                }
              }

    def initialize(path = nil)
      @config = process(path)
    end

    def process(path)
      custom = path ? JSON(File.read(path), :symbolize_names => true) : {}
      @config = @@default.merge(custom)
    end
  end
end
