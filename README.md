# SensuGenerator

SensuGenerator is a middleware providing dynamic monitoring with Consul and Sensu. It helps to set up dynamic monitoring systems. It generates check configurations from ERB templates according to *tags* listed in the KV and Consul service properties. It watches for changes Consul services state and special key in the KV. It triggers the following:
Sensu check configuration files are generated from the templates, the result will be synced via *rsync* and Sensu servers will be restarted using http Supervisord API. All files are generated when application starts and only changes will be processed.

All service checks *tag* are stored in the Consul Key-Value storage in *service/kv_tags_path* path, default *kv_tags_path* is "checks". Tag is the beginning of a service check template name and should be specified as a part of the template name in the Consul KV storage. Note that value should be comma-separated tags list. Rsync repo shuold be named as sensu service name.

It can can be used master server with multiple clients which send processed templates via tcp.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sensu_generator'
```

Install it yourself as:

    $ gem install sensu_generator

## Usage

sensu_generator start|stop|status|run -- [options]

##### Example:

**consul_url***/kv/nginx/checks*
```
check-http, check-tcp
```

Use ***svc*** (contains service data form consul) and ***check*** (contains *tag* name) in the ERB template.
***svc.kv_svc_props(key: key)*** can be used to access to ***svc/key*** data.
If key is not specified it will be requested the whole ***svc/*** folder.

Use Slack as notifier if you want.

##### Check ERB template example:

```
{
  "checks": {
    <% svc.properties.each do |instance| %>
    <% next if instance.ServiceTags.include? "udp" %>
     "check-ports-tcp-<%= "#{svc.name}-#{instance.ServiceAddress}-#{instance.ServicePort}" %>": {
       "command": "check-ports.rb -h <%= instance.ServiceAddress %> -p <%= instance.ServicePort %>",
       "subscribers": ["roundrobin:sensu-checker-node"],
       "handlers": ["slack"],
       "source": "<%= svc.name %>.service"
      }<%= "," if instance != svc.properties.last %>
    <% end %>
  }
}


```

## Configuration

##### server configuration:

```
"mode": "server",
"server": {
  "addr": "", //ip address to listen or left it empty to listen on 0.0.0.0
  "port": 12345 //listen port
}
```

##### client configuration:

```
"mode": "client",
"server": {
  "addr": "", //ip address or domain to connect to
  "port": 12345 //server port
}
```

See *sensu-generator.config.example* for more information.

## Development

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aksentyev/sensu_generator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
