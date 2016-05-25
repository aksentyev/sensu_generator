module SensuGenerator
  class ConsulService < Consul

    attr_reader :name, :properties, :checks

    def initialize(name:)
      @name    = name
      @changed = true
      @consul  = consul
      all_properties
      self
    end

    def all_properties
      properties = get_props.class == Array ? get_props.map {|el| el.to_h} : get_props.to_h
      @all_properties ||= { checks: get_checks, properties: properties }
    end

    alias :get_all_properties :all_properties

    def get_checks
      @checks ||= kv_svc_props(key: 'checks')
    end

    def get_props
      @properties ||= get_service_props(name)
    end

    def update
      old_all_properties = all_properties.clone
      reset
      get_all_properties
      @changed = true if all_properties != old_all_properties
    end

    def changed?
      @changed
    end

    def reset
      @all_properties = nil
      @properties     = nil
      @checks         = nil
      @changed = false
    end

    private

    def consul
      @consul ||= Consul.new
    end
  end
end
