module Geotrigger

  # +Device+ objects offer ORM-ish access to all attributes of a Device.
  #
  #   device.add_tags 'foo'
  #   device.save
  #
  #   device.remove_tags 'bar'
  #   device.properties = { foo: 'bar', baz: true, bat: 123 }
  #   device.save
  #
  class Device < Model
    include Taggable

    # Create a new +Device+ instance and load +@data+ from the API given a
    # +Hash+ with options:
    #
    # [device_id] +String+ id of the device
    # [tags] +Array+ name(s) of tag(s) to filter devices by
    #
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

    # Return the +String+ of this device's default tag.
    #
    def default_tag
      'device:%s' % deviceId
    end

    # POST the device's +@data+ to the API via 'device/update', and return
    # the same object with the new +@data+ returned from API call.
    #
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

    # Reads the data specific to this +Device+ from the API response and sets
    # it in +@data+.
    #
    # [data] +Hash+ the API response
    # [id] +String+ the id of the Device to pull out (first if nil)
    #
    def grok_self_from data, id = nil
      if id == :first
        @data = data['devices'].first
      else
        @data = data['devices'].select {|t| t['deviceId'] == (id || @data['deviceId'])}.first
      end
    end

  end

end
