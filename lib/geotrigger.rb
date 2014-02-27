# Geotrigger - A small Ruby client for the Esri Geotrigger Service.
# Copyright 2014 Esri; Nakamura, Kenichi (knakamura@esri.com)
#
# https://developers.arcgis.com/geotrigger-service/
# http://www.esri.com/
#
# [author] Kenichi Nakamura (knakamura@esri.com)
# [license] http://www.apache.org/licenses/LICENSE-2.0.txt

require 'forwardable'
require 'httpclient'
require 'json'

# HTTPClient's normal #inspect is quite large, ungainly in irb sessions
#
if $0 == 'irb'
  class HTTPClient
    alias_method :real_inspect, :inspect
    def inspect; self.to_s; end
  end
end

# The Geotrigger module is the main namespace for all things in this library.
#
module Geotrigger

  # raised by AGOSession on error from ArcGIS Online API
  #
  class AGOError < StandardError; end

  # raised by Session on error from Geotrigger API
  #
  class GeotriggerError < StandardError
    attr_accessor :code, :headers, :message, :parameters
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

require 'geotrigger/version'
