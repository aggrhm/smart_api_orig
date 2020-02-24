module SmartAPI

  module ControllerHelper

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def smart_api_options
        return {
          default_serializer_name: @default_serializer_name,
          engine_path: @engine_path
        }
      end
      def default_serializer_name(val)
        @default_serializer_name = val
      end
      def engine_path(val)
        @engine_path = val
      end

    end

    def request_context
      @request_context ||= begin
        actor = self.respond_to?(:current_user, true) ? current_user : nil
        RequestContext.new(params: params, actor: actor)
      end
    end

    def model_class
      @model_class ||= @endpoint[:class_name].constantize
    end

    def handle_api_request
      # determine mount
      mp = params[:qs_api_mount_path]
      @mount = SmartAPI::Endpoints.mounts[mp]
      # determine endpoint
      method = request.method.downcase.to_sym
      path = request.path
      eng_path = self.class.smart_api_options[:engine_path]
      if eng_path.present?
        path = path[eng_path.length..-1]
      end
      #puts path
      @endpoint = @mount.endpoints[ [method, path] ]
      res = call_endpoint_action(@endpoint)
      # call endpoint method
      render_result(res)
    end

    def call_endpoint_action(endpoint)
      if endpoint[:class_action].present?
        Rails.logger.info "Endpoint: #{endpoint[:class_name]}.#{endpoint[:class_action]}"
        res = model_class.send endpoint[:class_action], request_context.to_extended_params
      else
        # load model
        load_model_instance
        if (endpoint[:instantiate_if_nil] == true) && @model.nil?
          @model = model_class.new
        end
        Rails.logger.info "Endpoint: #{endpoint[:class_name]}.#{endpoint[:action]}"
        res = @model.send endpoint[:action], request_context.to_extended_params
      end
      return res
    end

    def model_scope_responder
      @model_scope_responder ||= begin
        opts = {model: model_class}
        if defined?(model_class::ScopeResponder)
          cls = model_class::ScopeResponder
        else
          cls = SmartAPI::ActiveRecordScopeResponder
        end
        cls.new(request_context, opts)
      end
    end

    def load_model_instance
      if params[:id].present?
        @model = model_scope_responder.item
        raise SmartAPI::Errors::ResourceNotFoundError if @model.nil?
      end
      return @model
    end

    # Render result to JSON using the serializers
    def render_result(res)
      rc = request_context
      status = res[:success] == true ? 200 : 500
      # find serializer for data
      ser_cls = serializer_class_for(res[:data])
      ser_opts = {
        request_context: rc
      }
      ser_opts[:fields] = rc.fields if rc.fields.present?
      json = ser_cls.new(res[:data], ser_opts).serialized_json
      render :json => json, :status => status
    end

    def serializer_class_for(data)
      # get data object
      if data.is_a?(Array)
        obj = data.first
      else
        obj = data
      end
      if obj.nil?
        serializer_name = self.class.smart_api_options[:default_serializer_name]
      else
        serializer_name = obj.class.name.to_s.classify + 'Serializer'
      end
      puts "Serializer used: " + serializer_name
      return serializer_name.constantize
    end

  end

end
