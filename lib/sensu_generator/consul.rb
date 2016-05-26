require 'json'
require 'diplomat'

module SensuGenerator
  class Consul
    attr_writer :config, :logger

    def initialize
      @config = config
      Diplomat.configure do |consul|
        config.get[:consul].each do |k, v|
          consul.public_send("#{k}=", v)
        end
      end
    end

    def sensu_servers
      get_service_props(config.get[:sensu][:service]).map {|el| el.ServiceAddress}.uniq.
        map {|addr| SensuServer.new(address: addr)}
    end

    def services
      Diplomat::Service.get_all.to_h
    end

    def get_service_props(svc)
      result = Diplomat::Service.get(svc, :all)
      result.class == Array ? result.map {|el| el.remove_consul_indexes} : result.remove_consul_indexes
    end

    def kv_svc_props(svc: name, key: nil)
      opts = key ? nil : {recurse: true}
      response = Diplomat::Kv.get("#{svc}/#{key}", opts)
      key ? JSON(response) : response # Maybe the feature of JSON check configuration will be implemented
    rescue
      if response
        if response.match(/\s+/) || key.to_s == config.get[:kv_tags_path] # tags value is designed to be a list even if it has only one element
          response.gsub(/\s+/, '').split(',')
        else
          response
        end
      else
        []
      end
    end

    private

    def config
      @config ||= Application.config
    end

    def logger
      @logger ||= Application.logger
    end
  end
end

class OpenStruct
  def remove_consul_indexes
    %w(CreateIndex ModifyIndex).each do |f|
      self.delete_field(f) if self.respond_to?(f)
    end
    self
  end
end
