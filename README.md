geotrigger-ruby
===============

a small ruby client for https://developers.arcgis.com/en/geotrigger-service/.

# Install

`gem install geotrigger`

# Usage

## Session

`Geotrigger::Session` is the main interface to the Geotrigger API. Once
created, it serves as the underlying support to all the Model subclasses.
Its main features are:

  * wrapping communication with the Geotrigger API
  * handling all `access_token` negotiation with ArcGIS Online

See also [API Doc](http://www.rubydoc.info/gems/geotrigger/Geotrigger/Session)

To create a `Session`, call `#new` with a optional Hash:

```ruby
# specify client_id and client_secret
#
session = Geotrigger::Session.new client_id: 'abcde', client_secret: '12345'
#=> <Geotrigger::Session ... >

# specify client_id and :device type
# (registers as a new device)
#
session = Geotrigger::Session.new client_id: 'abcde', type: :device
#=> <Geotrigger::Session ... >

# specify client_id, refresh_token, and :device type
# (gets access_tokens for an existing device)
#
session = Geotrigger::Session.new client_id: 'abcde', refresh_token: 'qwert', type: :device
#=> <Geotrigger::Session ... >

# reads config from ~/.geotrigger YAML
#
session = Geotrigger::Session.new
#=> <Geotrigger::Session ... >

# reads config from ~/.geotrigger YAML :dev key
#
session = Geotrigger::Session.new config: :dev
#=> <Geotrigger::Session ... >
```

You can then POST to any route in the API, without worring about managing
`access_token` lifecycles, with a normal Ruby `Hash` for both request
parameters and additional headers. The return value will be a normal Ruby
`Hash` parsed from the JSON response of the API. A `GeotriggerError` may be
raised if there was a problem with your request parameters or soemthing else.

```ruby
session.post 'trigger/list'
#=> { "triggers" => [] }

session.post 'device/update', deviceIds: ['abcd1234'], addTags: ['foo']
#=> { "devices" => [ { "deviceId" => "abcd1234", tags: ["foo", "device:abcd1234", ...] } ] }

begin
  session.post 'device/update', bad_param: false
rescue Geotrigger::GeotriggerError => ge

  ge.parameters
  #=> {"bad_param"=>[{"type"=>"invalid", "message"=>"Not a valid parameter for this request."}]}

end
```

You can do all of what you need to through this interface, but there are some
more lightweight utility classes for those that prefer a more OO approach.

## Models

These classes provide a ORM-ish interface to the Geotrigger API objects
Application, Trigger, Tag, and Device.

### Application

Application objects offer top-level access to various other model objects,
as well as updating of [Application](https://developers.arcgis.com/geotrigger-service/api-reference/application/) specific settings.

See also [API Doc](http://www.rubydoc.info/gems/geotrigger/Geotrigger/Application)

```
a = Geotrigger::Application.new client_id: 'abcde', client_secret: '12345'
#=> <Geotrigger::Application ... >

d = a.devices(tags: ['foo']).first
#=> <Geotrigger::Device ... >

geojson = JSON.parse File.load 'something.geojson'
t = a.triggers(geo: {geojson: geosjon}).first
#=> <Geotrigger::Trigger ... >

tag = a.tags.first
#=> <Geotrigger::Tag ... >
```

### Trigger

Trigger objects offer access to all attributes of a [Trigger](https://developers.arcgis.com/geotrigger-service/api-reference/trigger/).

See also [API Doc](http://www.rubydoc.info/gems/geotrigger/Geotrigger/Trigger)

```ruby
trigger.add_tags 'foo'
trigger.save

trigger.remove_tags 'bar'
trigger.properties = { foo: 'bar', baz: true, bat: 123 }
trigger.save
```

### Device

Device objects offer access to all attributes of a [Device](https://developers.arcgis.com/geotrigger-service/api-reference/device/).

See also [API Doc](http://www.rubydoc.info/gems/geotrigger/Geotrigger/Device)

```ruby
device.add_tags 'foo'
device.save

device.remove_tags 'bar'
device.properties = { foo: 'bar', baz: true, bat: 123 }
device.save

device.session.post 'location/update', locations: [{
  longitude: -122,
  latitude: 45,
  accuracy: 10,
  timestamp: DateTime.now.iso8601,
  trackingProfile: 'adaptive'
}]
```

### Tag

Tag objects offer access to all attributes of a [Tag](https://developers.arcgis.com/geotrigger-service/api-reference/tag/).

See also [API Doc](http://www.rubydoc.info/gems/geotrigger/Geotrigger/Tag)

```ruby
# create a new tag without applying it to any other objects
#
s = Geotrigger::Session.new
tag = Geotrigger::Tag.create s, name: 'foo', deviceTagging: false
#=> <Geotrigger::Tag ... >
```

Note that Tags are automatically created by the API, if needed, when added to a
Trigger or Device. This offers a way to create the Tag before applying it to
anything.

```ruby
a = Geotrigger::Application.new client_id: 'abcde', client_secret: '12345'
#=> <Geotrigger::Application ... >

tag = a.tags(tags: 'foo').first
#=> <Geotrigger::Tag ... >

tag.device_tagging = false
tag.trigger_list = false
tag.save
```
