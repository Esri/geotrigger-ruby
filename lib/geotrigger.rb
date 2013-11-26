require 'forwardable'
require 'httpclient'; class HTTPClient; def inspect; to_s; end; end
require 'json'

module Geotrigger
  class AGOError < StandardError; end
  class GeotriggerError < StandardError
    attr_accessor :code, :headers, :message, :params
  end
end

lib = File.expand_path '../..', __FILE__
$:.push lib unless $:.include? lib
require 'ext/string'

require 'geotrigger/ago/session'
require 'geotrigger/session'
require 'geotrigger/model'

require 'geotrigger/application'
require 'geotrigger/device'
require 'geotrigger/tag'
require 'geotrigger/trigger'
