require "smart_api/version"
require "smart_api/endpoints"
require "smart_api/controller_helper"
require "smart_api/request_context"
require "smart_api/helpers"
require "smart_api/scope_responder"

module SmartAPI
  # Your code goes here...
  extend Helpers

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
