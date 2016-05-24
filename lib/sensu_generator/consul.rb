require 'json'
require 'diplomat'

module SensuGenerator
  class Consul
    attr_accessor :config

    def initialize(config: Application.config)
      @config = config
      Diplomat.configure do |consul|
        config.get[:consul].each do |k, v|
          consul.public_send("#{k}=", v)
        end
      end
    end

    def sensu_servers
      get_service_props(config.get[:sensu][:service]).map {|hash| hash[:ServiceAddress]}.uniq.
        map {|addr| SensuServer.new(address: addr)}
    end

    def services
      Diplomat::Service.get_all.to_h
    end

    def get_service_props(svc)
      result = Diplomat::Service.get(svc, :all)
      result.class == Array ? result.map {|el| el.to_h.remove_consul_indexes} : result.to_h.remove_consul_indexes
    end

    def kv_checks_props(svc)
      response = Diplomat::Kv.get("#{svc}/checks")
      JSON(response)
    rescue
      response ? response.gsub(/\s+/, '').split(',') : []
    end
  end
end
