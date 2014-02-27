# Geotrigger - A small Ruby client for the Esri Geotrigger Service.
# Copyright 2014 Esri; Nakamura, Kenichi (knakamura@esri.com)
#
# https://developers.arcgis.com/geotrigger-service/
# http://www.esri.com/
#
# [author] Kenichi Nakamura (knakamura@esri.com)
# [license] http://www.apache.org/licenses/LICENSE-2.0.txt

module Geotrigger

  # +Session+ is the main interface to the Geotrigger API.
  #
  # Instances of it POST to the API and return the values using normal Ruby
  # Hashes. Used by objects subclassed from +Model+.
  #
  # Example:
  #
  #   session = Geotrigger::Session.new client_id: 'abcde', client_secret: '12345'
  #   session.post 'trigger/list'
  #   #=> { "triggers" => [ ... ] }
  #
  #   device_session = Geotrigger::Session.new client_id: 'abcde', type: :device
  #   device_session.post 'device/update', addTags: ['foo']
  #   #=> { "devices" => [{ "deviceId" => '0987qwer', tags: ["device:0987qwer", "foo"], ... }] }
  #
  #   device_session = Geotrigger::Session.new client_id: 'abcde', refresh_token: 'zxcvb', type: :device
  #   device_session.post 'device/list'
  #   #=> { "devices" => [{ "deviceId" => '1234zxcv', tags: ["device:1234zxcv"], ... }] }
  #
  # It can also read default values for the constructor options from
  # +ENV['HOME']/.geotrigger+, which is YAML formatted like:
  #
  #   :production:
  #     :client_id: abcde
  #     :client_secret: 12345
  #   :test:
  #     :client_id: qwert
  #     :client_secret: 67890
  #   :test_device:
  #     :client_id: qwert
  #     :refresh_token: 45678lmnop
  #     :type: :device
  #
  # It will load the first Hash it finds with value for key +:client_id+, or
  # one specified with the +:config+ option like:
  #
  #   # default to :production in the example
  #   s = Geotrigger::Session.new
  #
  #   # specify the :test_device config
  #   s = Geotrigger::Session.new config: :test_device
  #
  class Session
    extend Forwardable
    def_delegator :@ago, :type

    # Read the base URL for Geotrigger API from the environment, or use the
    # default.
    #
    #   $ GT_BASE_URL=http://example.com/path/ irb -rgeotrigger
    #
    # to have the client use that base URL.
    #
    BASE_URL = (ENV.key?('GT_BASE_URL') ?
               (ENV['GT_BASE_URL'] + '%s') :
               'https://geotrigger.arcgis.com/%s').freeze

    USER_CONFIG = File.join ENV['HOME'], '.geotrigger'

    attr_writer :access_token

    # Creates a Geotrigger::Session instance. Valid key/values for +opts+ are:
    #
    # [:client_id]     +String+ OAuth client id
    # [:client_secret] +String+ OAuth client secret
    # [:refresh_token] +String+ OAuth refresh token (used for +:device+ type)
    # [:type]          +Symbol+ +:application+ (default) or +:device+
    # [:config]        +Symbol+ key of options defaults in ~/.geotrigger
    #
    def initialize opts = {}
      if opts[:config] or opts.empty?
        if File.exist? USER_CONFIG
          require 'yaml'
          _opts = YAML.load_file USER_CONFIG
          _opts = _opts[opts[:config]] if opts[:config]
          while _opts[:client_id].nil? do
            _opts_keys ||= _opts.keys
            k = _opts_keys.shift
            raise if k.nil?
            _opts = _opts[k]
          end
          opts = _opts
        end
      end
      @ago = AGO::Session.new opts
      @hc = HTTPClient.new
    end

    # Returns a valid +access_token+. Gets a new one if +nil+ or expired.
    #
    def access_token
      @access_token || @ago.access_token
    end

    # Returns default request headers optionally merged with specified others.
    #
    # [others] +Hash+ other headers to include
    #
    def headers others = {}
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}",
        'X-GT-Client-Name' => 'geotrigger-ruby',
        'X-GT-Client-Version' => Geotrigger::VERSION
      }.merge others
    end

    # POST an API request to the given path, with optional params and
    # headers. Returns a normal Ruby +Hash+ of the response data.
    #
    # [params]        +Hash+ parameters to include in the request (will be converted to JSON)
    # [other_headers] +Hash+ headers to include in the request in addition to the defaults.
    #
    def post path, params = {}, other_headers = {}
      r = @hc.post BASE_URL % path, params.to_json, headers(other_headers)
      raise GeotriggerError.new r.body unless r.status == 200
      h = JSON.parse r.body
      raise_error h['error'] if h['error']
      h
    end

    # Creates and raises a +GeotriggerError+ from an API error response.
    #
    def raise_error error
      ge = GeotriggerError.new error['message']
      ge.code = error['code']
      ge.headers = error['headers']
      ge.message = error['message']
      ge.parameters = error['parameters']
      jj error
      raise ge
    end

    # True if Session is for a Device.
    #
    def device?
      type == :device
    end

    # True if Session is for an Application.
    #
    def application?
      type == :application
    end

  end

end
