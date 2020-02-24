require "smart_api/version"
require "smart_api/endpoints"
require "smart_api/controller_helper"
require "smart_api/request_context"
require "smart_api/helpers"
require "smart_api/scope_responder"
require "smart_api/model"
require "smart_api/errors"

module SmartAPI
  # Your code goes here...
  extend Helpers

  class Configuration

    def initialize
      self.default_model_index_method = :index_as_action!
      self.default_model_save_method = :update_as_action!
      self.default_model_delete_method = :delete_as_action!
      self.default_current_user_session_fields = ['id']
    end

    attr_accessor :default_model_index_method
    attr_accessor :default_model_save_method
    attr_accessor :default_model_delete_method

    attr_accessor :default_current_user_session_fields
  end

  def self.config
    @config ||= SmartAPI::Configuration.new
  end

end

if defined?(Rails::Railtie)
  class ActionDispatch::Routing::Mapper

    def mount_api_endpoints(mount_path, opts={}, &block)
      mount = nil
      if block
        mount = SmartAPI::Endpoints.configure(mount_path, opts, &block)
      else
        mount = SmartAPI::Endpoints.mounts[mount_path]
      end
      mount.endpoints.each do |key, val|
        method, path = key
        match path, controller: mount.controller, action: "handle_api_request", via: method, defaults: {qs_api_mount_path: mount.path}
      end
    end

  end

end
