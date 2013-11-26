module Geotrigger
  module AGO
    class Session
      extend ::Forwardable
      def_delegators :@impl, :access_token, :access_token=, :ago_data, :device_data, :refresh_token

      AGO_BASE_URL = (ENV.key?('AGO_BASE_URL') ?
                      (ENV['AGO_BASE_URL'] + '%s') :
                      'https://www.arcgis.com/sharing/%s').freeze

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

      def type
        case @impl
        when Application
          :application
        when Device
          :device
        end
      end

      # http the specified method to the specified path with the given params.
      # json parse the response body or raise errors.
      #
      def hc meth, path, params
        r = @hc.__send__ meth, AGO_BASE_URL % path, params.merge(f: 'json')
        raise AGOError.new r.body unless r.status == 200
        h = JSON.parse r.body
        raise AGOError.new r.body if h['error']
        h
      end

      module ExpirySet

        TOKEN_EXPIRY_BUFFER = 10

        def wrap_token_retrieval &block
          yield
          expires_at = Time.now.to_i + @ago_data['expires_in']
          @ago_data[:expires_at] = Time.at expires_at - TOKEN_EXPIRY_BUFFER
          @ago_data
        end

      end

      class Application
        include ExpirySet
        extend ::Forwardable
        def_delegator :@session, :hc

        attr_reader :ago_data

        def initialize session, opts = {}
          @session, @client_id, @client_secret =
            session, opts[:client_id], opts[:client_secret]
        end

        def access_token
          fetch_access_token if @ago_data.nil? or
                                (not @ago_data[:expires_at].nil? and
                                Time.now >= @ago_data[:expires_at])
          @ago_data['access_token']
        end

        private

        def fetch_access_token
          wrap_token_retrieval do
            @ago_data = hc :post, 'oauth2/token',
              client_id: @client_id,
              client_secret: @client_secret,
              grant_type: 'client_credentials'
          end
        end

      end

      class Device
        include ExpirySet
        extend Forwardable
        def_delegator :@session, :hc

        attr_accessor :refresh_token
        attr_reader :ago_data

        def initialize session, opts = {}
          @session, @client_id, @refresh_token =
            session, opts[:client_id], opts[:refresh_token]
        end

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

        def device_data
          @device_data ||= hc(:get, 'portals/self', token: access_token)['deviceInfo']
        end

        private

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
