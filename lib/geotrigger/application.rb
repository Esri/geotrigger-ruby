module Geotrigger

  # Application objects offer top-level, ORM-ish access to various other model
  # objects, as well as updating of application specific settings.
  #
  #   a = Geotrigger::Application.new client_id: 'abcde', client_secret: '12345'
  #   #=> <Geotrigger::Application ...>
  #
  #   # or
  #
  #   s = Geotrigger::Session.new client_id: 'abcde', client_secret: '12345'
  #   a = Geotrigger::Application.new session: s
  #   #=> <Geotrigger::Application ...>
  #
  class Application < Model

    # Return this application's default tag permissions as a +Hash+.
    #
    #   a.permissions
    #   #=> {"deviceTagging"=>true, "deviceLocation"=>false, ... }
    #
    def permissions
      post 'application/permissions'
    end

    # Update this application's default tag permissions with a +Hash+.
    #
    #   a.permissions = { deviceTagging: false }
    #   #=> {:deviceTagging => false }
    #
    #   a.permissions
    #   #=> {"deviceTagging"=>false, "deviceLocation"=>false, ... }
    #
    def permissions= perms
      post 'application/permissions/update', perms
    end

    # Return an +Array+ of +Device+ model objects that belong to this
    # application.
    #
    # [params] +Hash+ optional parameters to send with the request
    #
    #   a.devices tags: 'foo'
    #   #=> [<Geotrigger::Device ...>, ...] # (devices that have the tag 'foo' on them)
    #
    #   a.devices geo: { geojson: { type: "Feature", properties: nil, geometry: {
    #     type:"Polygon",coordinates:[[[-122.669085113593,45.4999973537201], ... ,[-122.669085113593,45.4999973537201]]]
    #   }}}
    #   #=> [<Geotrigger::Device ...>, ...] # (devices whose last location was inside the given polygon)
    #
    def devices params = {}
      post_list 'devices', params
    end

    # Return an +Array+ of +Tag+ model objects that belong to this
    # application.
    #
    # [params] +Hash+ optional parameters to send with the request
    #
    #   a.tags
    #   #=> [<Geotrigger::Tag...>, ...]
    #
    def tags params = {}
      post_list 'tags', params
    end

    # Return an +Array+ of +Trigger+ model objects that belong to this
    # application.
    #
    # [params] +Hash+ optional parameters to send with the request
    #
    #   a.triggers tags: 'foo'
    #   #=> [<Geotrigger::Trigger ...>, ...] # (triggers that have the tag 'foo' on them)
    #
    #   a.triggers geo: { geojson: { type: "Feature", properties: nil, geometry: {
    #     type:"Polygon",coordinates:[[[-122.669085113593,45.4999973537201], ... ,[-122.669085113593,45.4999973537201]]]
    #   }}}
    #   #=> [<Geotrigger::Trigger ...>, ...] # (triggers whose condition polygon is inside the given polygon)
    #
    def triggers params = {}
      post_list 'triggers', params
    end

  end

end
