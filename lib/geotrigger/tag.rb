module Geotrigger

  class Tag < Model

    def self.create session, opts
      t = ::Geotrigger::Tag.new session: session
      t.data = opts
      t.data[:tags] = t.data.delete :name if t.data[:name]
      t.post_create
    end

    def initialize opts = {}
      super opts
      if opts[:name] and @data.nil?
        grok_self_from post('tag/list', tags: opts[:name]), opts[:name]
      end
    end

    def triggers params = {}
      post_list 'triggers', params, tags: name
    end

    def devices params = {}
      post_list 'devices', params, tags: name
    end

    def post_create
      post_data = @data.dup
      grok_self_from post('tag/permissions/update', post_data), @data[:tags]
      self
    end

    def post_update
      raise StateError.new 'device access_token prohibited' if @session.device?
      post_data = @data.dup
      post_data['tags'] = post_data.delete 'name'
      grok_self_from post 'tag/permissions/update', post_data
      self
    end
    alias_method :save, :post_update

    def grok_self_from data, name = nil
      @data = data['tags'].select {|t| t['name'] == (name || @data['name'])}.first
    end

  end

end
