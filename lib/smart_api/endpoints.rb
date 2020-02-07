module SmartAPI

  module Endpoints

    def self.mounts
      @mounts ||= {}
    end

    def self.configure(path, opts={}, &block)
      mount = EndpointMount.new(path, opts)
      mount.instance_exec(&block)
      mounts[path] = mount
      return mount
    end

    class EndpointMount

      attr_reader :controller, :path, :endpoints

      def initialize(path, opts)
        @path = path
        @name = opts[:name]
        @controller = opts[:controller] || "api"
        @class_name = opts[:class_name]
        @endpoints = {}
        @options = opts
        @endpoint_options = {mount: self, class_name: opts[:class_name]}
      end

      def model_endpoints_for(model, opts={}, &block)
        ms = model.to_s.underscore
        mp = ms.pluralize
        #puts "Adding route for #{rp}"
        ep = EndpointBuilder.new(mount: self, class_name: model)
        if opts[:crud] != false
          ep.get mp, class_name: model, class_action: SmartAPI.config.default_model_index_method
          ep.post ms, class_name: model, action: SmartAPI.config.default_model_save_method, instantiate_if_nil: true
          ep.delete ms, class_name: model, action: SmartAPI.config.default_model_delete_method
        end
        ep.instance_exec(&block) if block
      end

    end

    class EndpointBuilder

      def initialize(opts)
        @mount = opts[:mount]
        @endpoint_options = {class_name: opts[:class_name]}
      end

      def post(path, opts)
        add_endpoint(:post, path, opts)
      end

      def get(path, opts)
        add_endpoint(:get, path, opts)
      end

      def delete(path, opts)
        add_endpoint(:delete, path, opts)
      end

      def add_endpoint(method, path, opts)
        method = method.to_sym
        key = [method, File.join(@mount.path, path)]
        opts[:method] = method
        opts[:path] = path
        @mount.endpoints[key] = @endpoint_options.merge(opts)
      end

    end

  end

end
