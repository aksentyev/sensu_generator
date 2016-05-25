# SensuGenerator

SensuGenerator is an intermediate layer between Consul and Sensu. It helps to set up dynamic monitoring systems. It generates check configurations from ERB templates according to *tags* listed in the KV and Consul service properties. Files generated from templates will be synced via *rsync* and Sensu servers will be restarted using http Supervisord API. All files are generated when application starts and only changes will be processed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sensu_generator'
```

Install it yourself as:

    $ gem install sensu_generator

## Usage

sensu_generator start|stop|status -- [options]

All service checks *tag* are stored in the Consul Key-Value storage in *checks* folder. Tag is the beginning of a service check template name and should be specified as a part of value in the Consul KV storage. Note that value should be comma-separated tags list.

##### Example:

**consul_url***/kv/nginx/checks*
```
[check-http, check-tcp]
```

Use ***svc*** (contains service data form consul) and ***check*** (contains *tag* name) in the ERB template.

Use Slack as notifier if you want.

Use *sensu-generator.config.example* to make your own.

##### Check ERB template example:

```
{
  "checks": {
    <% svc.each do |instance| -%>
      <% if svc.tags.include? "udp" %>
       "check-api-drone-<%= instance.port %>": {
         "command": "check-ports.rb -h <%= instance.name %>.service.consul -P udp",
         "subscribers": ["roundrobin:sensu-checker-node"],
         "handlers": ["slack"],
         "source": "<%= instance.name %>.service"
       }<%= "," if svc[-1] == instance %>
      <% end %>
    <% end %>
  }
}

```

NOTE There are no tests for this ~~legacy shit~~ application.

## Development

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sensu_generator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
