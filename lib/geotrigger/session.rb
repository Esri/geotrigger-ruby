module Geotrigger

  class Session
    extend Forwardable
    def_delegator :@ago, :type

    BASE_URL = (ENV.key?('GT_BASE_URL') ?
               (ENV['GT_BASE_URL'] + '%s') :
               'https://geotrigger.arcgis.com/%s').freeze

    USER_CONFIG = File.join ENV['HOME'], '.geotrigger'

    attr_writer :access_token

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

    def access_token
      @access_token || @ago.access_token
    end

    def headers others = {}
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}",
        'X-GT-Client-Name' => 'geotrigger-ruby',
        'X-GT-Client-Version' => Geotrigger::VERSION
      }.merge others
    end

    def post path, params = {}, other_headers = {}
      r = @hc.post BASE_URL % path, params.to_json, headers(other_headers)
      raise GeotriggerError.new r.body unless r.status == 200
      h = JSON.parse r.body
      raise_error h['error'] if h['error']
      h
    end

    def raise_error error
      ge = GeotriggerError.new error['message']
      ge.code = error['code']
      ge.headers = error['headers']
      ge.message = error['message']
      ge.params = error['params']
      jj error
      raise ge
    end

    def device?
      type == :device
    end

    def application?
      type == :application
    end

  end

end
