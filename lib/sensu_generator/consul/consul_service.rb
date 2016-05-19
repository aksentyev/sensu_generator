module SensuGenerator
  class ConsulService < Consul

    attr_reader :name, :properties, :checks

    def initialize(consul:, name:)
      @properties = []
      @checks = []
      @consul = consul
      @name   = name
      @changed = true
      all_properties
      self
    end

    def all_properties
      @all_properties ||= { checks: get_checks, properties: get_props }
    end

    def get_checks
      @checks = @consul.kv_checks_props(name) if @checks.empty?
    end

    def get_props
      @properties = @properties.empty? ? @consul.get_service_props(name) : @properties
    end

    def update
      old_all_properties = all_properties
      empty
      changed = true if all_properties != old_all_properties
      reset
    end

    def changed?
      @changed
    end

    def reset
      @all_properties = {}
      @properties     = {}
      @checks         = {}
      @changed = false
    end
  end
end
