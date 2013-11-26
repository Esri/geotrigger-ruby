module Geotrigger

  class Session
    extend Forwardable
    def_delegator :@ago, :type

    BASE_URL = (ENV.key?('GT_BASE_URL') ?
               (ENV['GT_BASE_URL'] + '%s') :
               'https://geotrigger.arcgis.com/%s').freeze

    attr_writer :access_token

    def initialize opts = {}
      @ago = AGO::Session.new opts
      @hc = HTTPClient.new
    end

    def access_token
      @access_token || @ago.access_token
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}"
      }
    end

    def post path, params = {}
      r = @hc.post BASE_URL % path, params.to_json, headers
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
