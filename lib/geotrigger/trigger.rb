module Geotrigger

  # +Trigger+ objects offer ORM-ish access to all attributes of a Trigger.
  #
  #   trigger.add_tags 'foo'
  #   trigger.save
  #
  #   trigger.remove_tags 'bar'
  #   trigger.properties = { foo: 'bar', baz: true, bat: 123 }
  #   trigger.save
  #
  class Trigger < Model
    include Taggable

    CIRCLE_KEYS = %w[latitude longitude distance]

    # Create a Trigger with the given +Session+ and options.
    #
    #   s = Geotrigger::Session.new
    #   t = Geotrigger::Trigger.create s, condition: { ... }, action: { ... }, tags: ['foo']
    #   #=> <Geotrigger::Trigger ... >
    #
    def self.create session, opts
      t = Trigger.new session: session
      t.data = opts
      t.post_create
    end

    # Create a new +Trigger+ instance and load +@data+ from the API given a
    # +Hash+ with options:
    #
    # [tags] +Array+ name(s) of tag(s)
    #
    def initialize opts = {}
      super opts
      if opts[:trigger_id] and @data.nil?
        grok_self_from post('trigger/list', triggerIds: opts[:trigger_id]), opts[:trigger_id]
      end
    end

    # Return the +String+ of this trigger's default tag.
    #
    def default_tag
      'trigger:%s' % triggerId
    end

    # Creates a trigger by POSTing to trigger/create with +@data+.
    #
    def post_create
      post_data = @data.dup
      @data = post 'trigger/create', post_data
      self
    end

    # POST the trigger's +@data+ to the API via 'trigger/update', and return
    # the same object with the new +@data+ returned from API call.
    #
    def post_update opts = {}
      post_data = @data.dup
      post_data['triggerIds'] = post_data.delete 'triggerId'
      post_data.delete 'tags'

      if circle?
        post_data['condition']['geo'].delete 'geojson'
        post_data['condition']['geo'].delete 'esrijson'
      end

      grok_self_from post 'trigger/update', post_data.merge(opts)
      self
    end
    alias_method :save, :post_update

    # Reads the data specific to this +Trigger+ from the API response and sets
    # it in +@data+.
    #
    # [data] +Hash+ the API response
    # [triggerId] +String+ the id of the trigger to pull out (first if nil)
    #
    def grok_self_from data, id = nil
      @data = data['triggers'].select {|t| t['triggerId'] == (id || @data['triggerId'])}.first
    end

    # True if trigger is a "circle" type, meaning it has a point(longitude,latitude) and
    # radius(distance) in its condition, rather than only a geojson or esrijson geometry.
    #
    def circle?
      not CIRCLE_KEYS.map {|k| @data['condition']['geo'].keys.include? k}.select {|e| e}.empty?
    end

  end

end
