module SmartAPI

  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def scope_responder(ctx, opts={})
        opts[:model] ||= self
        if defined?(self::ScopeResponder)
          cls = self::ScopeResponder
        else
          cls = SmartAPI::ActiveRecordScopeResponder
        end
        cls.new(ctx, opts)
      end

      def index_as_action!(opts)
        ctx = opts[:request_context] || SmartAPI::RequestContext.new(opts)
        res = scope_responder(ctx).result
        return res
      end

      def scope_names
        return @scope_names ||= []
      end

      def scope(name, body, &block)
        ret = super(name, body, &block)
        scope_names << name
        return ret
      end

    end

    # INSTANCE METHODS

    def update_fields_from(data, fields, options={})
      fields.each do |field|
        if data.key?(field)
          val = data[field]
          if options[:strip] != false
            val = val.strip if val.respond_to?(:strip)
          end
          self.send "#{field.to_s}=", val
        end
      end
    end

    def error_message
      self.error_messages.first
    end

    def error_messages
      self.errors.messages.values.flatten
    end

    def has_present_association?(assoc)
      self.association(assoc).loaded? && self.send(assoc).present?
    end

  end

end
