module SmartAPI

  class RequestContext

    attr_accessor :actor, :selectors, :args, :limit, :page, :offset, :fields, :includes, :enhances, :sort
    attr_reader :params, :includes_tree, :enhances_tree

    def initialize(opts)
      if opts[:params]
        @params = opts[:params] || {}
        @actor = opts[:actor]
      else
        @params = opts
        @actor = opts[:request_actor] || opts[:actor]
      end
      @limit = 100
      @page = 1
      @offset = 0
      @fields = {}
      @includes = []
      @enhances = []
      @includes_tree = {}
      @enhances_tree = {}
      @enhances = []
      @selectors = {}
      if params[:scope]
        @selectors = SmartAPI.parse_opts(params[:scope])
      end
      @limit = params[:limit].to_i if params[:limit]
      @page = params[:page].to_i if params[:page]
      @offset = (@page - 1) * @limit if params[:page] && params[:limit]
      self.fields = SmartAPI.parse_opts(params[:fields]) if params[:fields]
      self.includes = SmartAPI.parse_opts(params[:include]) if params[:include]
      self.enhances = SmartAPI.parse_opts(params[:enhance]) if params[:enhance]
      @sort = SmartAPI.parse_opts(params[:sort]) if params[:sort]
    rescue => ex
      SmartAPI.log_exception(ex)
    end

    def selector_names
      @selectors.keys
    end

    def scope
      @selectors
    end

    def includes=(val)
      @includes = val || []
      @includes_tree = SmartAPI.bool_tree(@includes)
    end
    def enhances=(val)
      @enhances = val || []
      @enhances_tree = SmartAPI.bool_tree(@enhances)
    end

    # use this when need a subcontext hash
    def to_extended_params(opts=nil)
      opts ||= params
      ret = opts.merge(request_actor: actor, request_context: self)
      #ret[:actor] ||= actor
      return ret
    end

    def to_opts(opts=nil)
      to_extended_params(opts)
    end

  end


end
