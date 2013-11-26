module Geotrigger

  class Trigger < Model
    include Taggable

    def self.create session, opts
      t = Trigger.new session: session
      t.data = opts
      t.post_create
    end

    def initialize opts = {}
      super opts
      if opts[:trigger_id] and @data.nil?
        grok_self_from post('trigger/list', triggerIds: opts[:trigger_id]), opts[:trigger_id]
      end
    end

    def default_tag
      'trigger:%s' % triggerId
    end

    def post_create
      post_data = @data.dup
      @data = post 'trigger/create', post_data
      self
    end

    def post_update opts = {}
      post_data = @data.dup
      post_data['triggerIds'] = post_data.delete 'triggerId'
      post_data.delete 'tags'

      grok_self_from post 'trigger/update', post_data.merge(opts)
      self
    end
    alias_method :save, :post_update

    def grok_self_from data, id = nil
      @data = data['triggers'].select {|t| t['triggerId'] == (id || @data['triggerId'])}.first
    end

  end

end
