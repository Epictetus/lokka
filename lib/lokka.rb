require 'rubygems'
require 'pathname'
require 'erb'
require 'ostruct'
require 'digest/sha1'

require 'active_support/all'
require 'rack-flash'
require 'sinatra/base'
require 'sinatra/r18n'
require 'sinatra/logger'
require 'sinatra/content_for'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-validations'
require 'dm-types'
require 'dm-is-tree'
require 'dm-tags'
require 'dm-pager'
require 'haml'
require 'builder'
require 'exceptional'

require 'lokka/theme'
require 'lokka/user'
require 'lokka/site'
require 'lokka/entry'
require 'lokka/category'
require 'lokka/tag'
require 'lokka/comment'
require 'lokka/bread_crumb'
require 'lokka/before'
require 'lokka/helpers'

require 'lokka/hello'

require 'lokka/app'


module Lokka
  class NoTemplateError < StandardError; end
end
