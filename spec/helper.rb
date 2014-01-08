lib = File.expand_path '../..', __FILE__
$:.unshift lib unless $:.include? lib

require 'yaml'
CONF = YAML.load_file File.expand_path '../config.yml', __FILE__

require 'timecop'
require 'geotrigger'
require 'pry'
