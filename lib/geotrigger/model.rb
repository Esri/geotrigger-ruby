module Geotrigger

  # Superclass for Geotrigger "objects" - +Application+, +Trigger+, +Device+,
  # +Tag+.
  #
  # Contains the base logic for interacting with the Geotrigger API in an
  # ORM-like fashion. Never instantiated directly by the user.
  #
  class Model

    class StateError < StandardError; end

    extend Forwardable
    def_delegator :@session, :post

    # The data behind the model object.
    #
    attr_accessor :data

    # The +Session+ the model object uses to talk to the API.
    #
    attr_reader :session

    # Create an instance of the subclassed model object from data retrieved
    # from the API.
    #
    def self.from_api data, session
      i = self.new session: session
      i.data = data
      return i
    end

    # Create an instance and from given options +Hash+.
    #
    # [:session] +Session+ underlying session to use when talking to the API
    #
    def initialize opts = {}
      @session = opts[:session] || Session.new(opts)
    end

    # POST a request to this model's /list route, passing parameters. Returns
    # a new instance of the model object with populated data via
    # +Model.from_api+.
    #
    # [models] +String+ name of the model to request listed data for
    # [params] +Hash+ parameters to send with the request
    # [default_params] +Hash+ default parameters to merge +params+ into
    #
    def post_list models, params = {}, default_params = {}
      model = models.sub /s$/, ''
      params = default_params.merge params
      post(model + '/list', params)[models].map do |data|
        Geotrigger.const_get(model.capitalize).from_api data, @session
      end
    end

    # Allows snake_case accessor to top-level data values keyed by their
    # camelCase counterparts. An attempt to be moar Rubyish.
    #
    #   device.tracking_profile
    #   #=> 'adaptive'
    #
    #   device.trackingProfile
    #   #=> 'adaptive'
    #
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

    # Compares underlying data for equality.
    #
    def == obj
      if Model === obj
        self.data == obj.data
      else
        false
      end
    end

    # Mixin for +Trigger+ and +Device+ to add tag functionality.
    #
    module Taggable

      # Returns this model's tags as an +Array+ of +Tag+ objects.
      #
      def tags params = {}
        post_list 'tags', params, tags: @data['tags']
      end

      # Sets 'addTags' in this model's +@data+ for POSTing to the API via
      # +Model#save+.
      #
      #   device.add_tags 'foo', 'bar'
      #   device.save
      #
      def add_tags *names
        @data['addTags'] = names.flatten
      end

      # Sets 'removeTags' in this model's +@data+ for POSTing to the API via
      # +Model#save+.
      #
      #   trigger.remove_tags 'foo', 'bar'
      #   trigger.save
      #
      def remove_tags *names
        names = names.flatten
        raise ArgumentError.new "default tag prohibited" if names.include? default_tag
        @data['removeTags'] = names
      end


      # Sets 'setTags' in this model's +@data+ for POSTing to the API via
      # +Model#save+.
      #
      #   trigger.tags = ['foo', 'bar']
      #   trigger.save
      #
      def tags= *names
        names = names.flatten
        raise ArgumentError.new "default tag required" unless names.include? default_tag
        @data['setTags'] = names
      end

    end

  end

end
