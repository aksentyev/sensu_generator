module SensuGenerator
  class ConsulService < Consul

    attr_reader :name, :properties, :checks

    def initialize(consul:, name:)
      @consul = consul
      @name   = name
      @changed = true
      all_properties
      self
    end

    def all_properties
      @all_properties ||= { checks: get_checks, properties: get_props }
    end

    alias :get_all_properties :all_properties

    def get_checks
      @checks ||= @consul.kv_checks_props(name)
    end

    def get_props
      @properties ||= @consul.get_service_props(name)
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
  end
end
