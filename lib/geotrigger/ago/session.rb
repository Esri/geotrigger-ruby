module Geotrigger

  # namespace for interacting with the ArcGIS Online API.
  #
  module AGO

    # AGO::Session is responsible for talking to the ArcGIS Online API.
    #
    # * retrieves a valid OAuth +access_token+, handling expiration
    #   * Application, via +client_credentials+
    #   * Device, via registration or +refresh_token+
    # * registers a new Device given a +client_id+
    #
    # Generally, one interacts with only the +Session+, which retains an
    # instance of this to deal with tokens.
    #
    class Session

      extend ::Forwardable
      def_delegators :@impl, :access_token, :access_token=, :ago_data, :device_data, :refresh_token

      # Read the base URL for ArcGIS Online API from the environment,
      # or use the default.
      #
      # If you have a different OAuth portal, you can:
      #
      #   $ AGO_BASE_URL=http://example.com/path/ irb -rgeotrigger
      #
      # to have the client use that base URL.
      #
      AGO_BASE_URL = (ENV.key?('AGO_BASE_URL') ?
                      (ENV['AGO_BASE_URL'] + '%s') :
                      'https://www.arcgis.com/sharing/%s').freeze

      # Determines underlying implementation type, and creates an HTTPClient
      # instance.
      #
      # [opts] +Hash+ options for construction:
      #   [:client_id]     +String+ OAuth client id
      #   [:client_secret] +String+ OAuth client secret
      #   [:refresh_token] +String+ OAuth refresh token
      #   [:type]          +Symbol+ +:application+ (default) or +:device+
      #
      def initialize opts = {}
        @hc = HTTPClient.new
        @impl = case opts[:type] || :application
                when :application
                  Application.new self, opts
                when :device
                  Device.new self, opts
                else
                  raise ArgumentError 'unknown type'
                end
      end

      # Type of implementation as a symbol.
      #
      def type
        case @impl
        when Application
          :application
        when Device
          :device
        end
      end

      # HTTP the specified method to the specified path with the given params.
      # JSON parse the response body or raise errors.
      #
      # [meth]   +Symbol+ of the method to HTTP (:get,:post...)
      # [path]   +String+ path of the request ('/example/index.html')
      # [params] +Hash+ parameters for the request
      #
      def hc meth, path, params
        r = @hc.__send__ meth, AGO_BASE_URL % path, params.merge(f: 'json')
        raise AGOError.new r.body unless r.status == 200
        h = JSON.parse r.body
        raise AGOError.new r.body if h['error']
        h
      end

      # Mixin for the AGO::Session underlying implementation.
      #
      module ExpirySet

        # Number of seconds before expiration to refresh tokens.
        #
        TOKEN_EXPIRY_BUFFER = 10

        # Sets a buffered +:expires_at+ for refreshing tokens. Generates this
        # value from +Time.now+ and the supplied +expires_in+ value (seconds).
        #
        def wrap_token_retrieval &block
          yield
          expires_at = Time.now.to_i + @ago_data['expires_in']
          @ago_data[:expires_at] = Time.at expires_at - TOKEN_EXPIRY_BUFFER
          @ago_data
        end

      end

      # AGO::Session implementation for Applications
      #
      class Application
        include ExpirySet
        extend ::Forwardable
        def_delegator :@session, :hc

        attr_reader :ago_data

        # Accepts the abstract +AGO::Session+ and a +client_credentials+ Hash.
        #
        def initialize session, opts = {}
          @session, @client_id, @client_secret =
            session, opts[:client_id], opts[:client_secret]
        end

        # Returns a valid +access_token+. Gets a new one if +nil+ or expired.
        #
        def access_token
          fetch_access_token if @ago_data.nil? or
                                (not @ago_data[:expires_at].nil? and
                                Time.now >= @ago_data[:expires_at])
          @ago_data['access_token']
        end

        private

        # Gets a new +access_token+.
        #
        def fetch_access_token
          wrap_token_retrieval do
            @ago_data = hc :post, 'oauth2/token',
              client_id: @client_id,
              client_secret: @client_secret,
              grant_type: 'client_credentials'
          end
        end

      end

      # AGO::Session implementation for Devices
      #
      class Device
        include ExpirySet
        extend Forwardable
        def_delegator :@session, :hc

        attr_accessor :refresh_token
        attr_reader :ago_data

        # Accepts the abstract +AGO::Session+ and a Hash with +:client_id+
        # and +:refresh_token+ keys.
        #
        def initialize session, opts = {}
          @session, @client_id, @refresh_token =
            session, opts[:client_id], opts[:refresh_token]
        end

        # Returns a valid +access_token+. Registers a new Device with AGO if
        # needed.
        #
        def access_token
          if @ago_data.nil?
            if @refresh_token.nil?
              register
            else
              refresh_access_token
            end
          elsif not @ago_data[:expires_at].nil? and Time.now >= @ago_data[:expires_at]
            refresh_access_token
          end
          @ago_data['access_token']
        end

        # Fetches data from AGO about the device specified by this :access_token+.
        #
        def device_data
          @device_data ||= hc(:get, 'portals/self', token: access_token)['deviceInfo']
        end

        private

        # Registers as a new Device with AGO.
        #
        def register
          wrap_token_retrieval do
            data = hc :post, 'oauth2/registerDevice', client_id: @client_id, expiration: -1
            @ago_data = {
              'access_token' => data['deviceToken']['access_token'],
              'expires_in' => data['deviceToken']['expires_in']
            }
            @device_data = data['device']
            @refresh_token = data['deviceToken']['refresh_token']
          end
        end

        # Gets a new +access_token+.
        #
        def refresh_access_token
          wrap_token_retrieval do
            @ago_data = hc :post, 'oauth2/token',
              client_id: @client_id,
              refresh_token: @refresh_token,
              grant_type: 'refresh_token'
          end
        end

      end

    end
  end
end
