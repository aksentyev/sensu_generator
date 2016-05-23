require 'json'

module SensuGenerator
  class Config
    @@default = {
                :sensu => {
                  :check_default_params => {
                    :refresh => 86400,
                    :interval => 60,
                    :aggregate => true
                  },
                  :minimal_to_restart => 2,
                  :service => "sensu-server",
                  :supervisor => {:user => "", :password => ""},
                },
                :result_dir => "work/result",
                :templates_dir => "work/templates",
                :logger => {
                  :file => STDOUT,
                  :notify_level => "error",
                  :log_level => "debug"
                },
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

    def get
      @config
    end

    def process(path)
      custom = path ? JSON(File.read(path), :symbolize_names => true) : {}
      @config = @@default.deep_merge(custom)
    end
  end
end
