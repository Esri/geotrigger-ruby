module Geotrigger

  class Device < Model
    include Taggable

    def initialize opts = {}
      super opts
      case session.type
      when :application
        if opts[:device_id] and @data.nil?
          grok_self_from post('device/list', deviceIds: opts[:device_id]), opts[:device_id]
        end
      when :device
        if @data.nil?
          grok_self_from post('device/list'), opts[:device_id] || :first
        end
      end
    end

    def default_tag
      'device:%s' % deviceId
    end

    def post_update
      post_data = @data.dup
      case @session.type
      when :application
        post_data['deviceIds'] = post_data.delete 'deviceId'
      when :device
        post_data.delete 'deviceId'
      end
      post_data.delete 'tags'
      post_data.delete 'lastSeen'

      grok_self_from post 'device/update', post_data
      self
    end
    alias_method :save, :post_update

    def grok_self_from data, id = nil
      if id == :first
        @data = data['devices'].first
      else
        @data = data['devices'].select {|t| t['deviceId'] == (id || @data['deviceId'])}.first
      end
    end

  end

end
