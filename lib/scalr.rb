require 'rubygems'
require 'active_support/core_ext'

require File.dirname(__FILE__) + '/scalr/response'
require File.dirname(__FILE__) + '/scalr/request'
require File.dirname(__FILE__) + '/scalr/core_extensions/hash'
require File.dirname(__FILE__) + '/scalr/core_extensions/http'

module Scalr

  # set to a debugging output stream for HTTP request/response, nil for none
  mattr_accessor :debug
  @@debug = nil

  mattr_accessor :endpoint
  @@endpoint = "api.scalr.net"
  
  mattr_accessor :key_id
  @@key_id = nil
  
  mattr_accessor :access_key
  @@access_key = nil
  
  mattr_accessor :version
  @@version = "2.0.0"
  
  class << self
    
    def method_missing(method_id, *arguments)
      if matches_action? method_id
        request = Scalr::Request.new(method_id, @@endpoint, @@key_id, @@access_key, @@version, arguments)
        return request.process!
      else
        super
      end
    end
    
    private
    
      def matches_action?(method_id)
        Scalr::Request::ACTIONS.keys.include? method_id.to_sym
      end
    
  end
  
end
