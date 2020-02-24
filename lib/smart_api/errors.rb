module SmartAPI

  module Errors

    class APIError < StandardError
        def initialize(opts={})
          super
          if opts.is_a?(String)
            @message = opts
            @human_message = nil
            @resp = {}
          else
            opts ||= {}
            @resp = opts
            @message = opts[:message]
            @human_message = opts[:human_message]
          end
        end
        def message
          @message ||= "An error occurred at the server."
        end
        def human_message
          @human_message || message
        end
        def code
          1000
        end
        def type
          "APIError"
        end
        def resp
          @resp[:success] = false
          @resp[:meta] = self.code
          @resp[:data] ||= nil
          @resp[:error] = self.message
          @resp[:error_type] = self.type
          return @resp
        end
    end
    class ResourceNotFoundError < APIError
      def message
        @message ||= "The resource you are trying to load or update could not be found."
      end
      def code
        1003
      end
      def type
        "ResourceNotFoundError"
      end
    end
    class InvalidParamError < APIError
      def message
        @message ||= "A parameter you specified was invalid."
      end
      def code
        1004
      end
      def type
        "InvalidParamError"
      end
    end

  end

end
