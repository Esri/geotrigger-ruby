# basic string extensions
#
# these are pretty much ripped from:
#
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/inflector/methods.rb

class String

  def camelcase
    string = self.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    string.gsub!('/', '::')
    string
  end

  def underscore
    acronym_regex = /(?=a)b/
    word = self.gsub('::', '/')
    word.gsub!(/(?:([A-Za-z\d])|^)(#{acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end

end
