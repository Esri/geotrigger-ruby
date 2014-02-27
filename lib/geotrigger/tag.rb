module Geotrigger

  # +Tag+ objects offer ORM-ish access to all attributes of a Tag.
  #
  class Tag < Model

    # Create a Tag with the given +Session+ and options. Note that Tags are
    # automatically created by the API, if needed, when added to a Trigger
    # or Device. This offers a way to create the Tag before applying it to
    # anything.
    #
    #   s = Geotrigger::Session.new
    #   tag = Geotrigger::Tag.create s, name: 'foo', deviceTagging: false
    #   #=> <Geotrigger::Tag ... >
    #
    def self.create session, opts
      t = ::Geotrigger::Tag.new session: session
      t.data = opts
      t.data[:tags] = t.data.delete :name if t.data[:name]
      t.post_create
    end

    # Create a new +Tag+ instance and load +@data+ from the API given a +Hash+
    # with options:
    #
    # [name] +String+ name of the tag
    #
    def initialize opts = {}
      super opts
      if opts[:name] and @data.nil?
        grok_self_from post('tag/list', tags: opts[:name]), opts[:name]
      end
    end

    # Return an +Array+ of +Trigger+ objects in this Application that have this
    # tag applied to them.
    #
    # [params] +Hash+ any additional parameters to include in the request (trigger/list)
    #
    def triggers params = {}
      post_list 'triggers', params, tags: name
    end

    # Return an +Array+ of +Device+ objects in this Application that have this
    # tag applied to them.
    #
    # [params] +Hash+ any additional parameters to include in the request (device/list)
    #
    def devices params = {}
      post_list 'devices', params, tags: name
    end

    # Creates a tag by POSTing to tag/permissions/update with +@data+.
    #
    def post_create
      post_data = @data.dup
      grok_self_from post('tag/permissions/update', post_data), @data[:tags]
      self
    end

    # POST the tag's +@data+ to the API via 'tag/permissions/update', and return
    # the same object with the new +@data+ returned from API call.
    #
    def post_update
      raise StateError.new 'device access_token prohibited' if @session.device?
      post_data = @data.dup
      post_data['tags'] = post_data.delete 'name'
      grok_self_from post 'tag/permissions/update', post_data
      self
    end
    alias_method :save, :post_update

    # Reads the data specific to this +Tag+ from the API response and sets
    # it in +@data+.
    #
    # [data] +Hash+ the API response
    # [name] +String+ the name of the Tag to pull out
    #
    def grok_self_from data, name = nil
      @data = data['tags'].select {|t| t['name'] == (name || @data['name'])}.first
    end

  end

end
