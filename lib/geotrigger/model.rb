module Geotrigger

  class Model

    class StateError < StandardError; end

    extend Forwardable
    def_delegator :@session, :post

    attr_accessor :data
    attr_reader :session

    def self.from_api data, session
      i = self.new session: session
      i.data = data
      return i
    end

    def initialize opts = {}
      @session = opts[:session] || Session.new(opts)
    end

    def post_list models, params = {}, default_params = {}
      model = models.sub /s$/, ''
      params = default_params.merge params
      post(model + '/list', params)[models].map do |data|
        Geotrigger.const_get(model.capitalize).from_api data, @session
      end
    end

    def method_missing meth, *args
      meth_s = meth.to_s
      if meth_s =~ /=$/ and args.length == 1
        key = meth_s.sub(/=$/,'').camelcase
        if @data and @data.key? key
          @data[key] = args[0]
        else
          super meth, *args
        end
      else
        key = meth_s.camelcase
        if @data and @data.key? key
          @data[key]
        else
          super meth, *args
        end
      end
    end

    def == obj
      if Model === obj
        self.data == obj.data
      else
        false
      end
    end

    module Taggable

      def tags params = {}
        post_list 'tags', params, tags: @data['tags']
      end

      def add_tags *names
        @data['addTags'] = names.flatten
      end

      def remove_tags *names
        names = names.flatten
        raise ArgumentError.new "default tag prohibited" if names.include? default_tag
        @data['removeTags'] = names
      end

      def tags= *names
        names = names.flatten
        raise ArgumentError.new "default tag required" unless names.include? default_tag
        @data['setTags'] = names
      end

    end

  end

end
