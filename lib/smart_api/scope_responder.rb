module SmartAPI

  class ScopeResponder
    attr_reader :request_context, :options

    def initialize(request_context, opts={}, &block)
      @options = opts
      @request_context = request_context
      @names = {}.with_indifferent_access
      prepare
      block.call(self) if block
    end

    def prepare

    end

    def scopes
      @names
    end

    def scope_for_name(name)
      @names[name]
    end

    def base_scope
      options[:base_scope]
    end

    def base_selectors
      {}
    end

    def query_selectors
      base_selectors.merge(request_context.selectors)
    end

    def base_relation
      base_scope
    end

    def actor
      request_context.actor
    end

    def build_database_relation(opts={})
      crit = base_relation

      query_selectors.each do |k, v|
        ds = scope_for_name(k)

        if ds.nil? and options[:strict_scopes] != false
          raise SmartAPI::Errors::APIError, "#{k} is not a valid scope"
        end
        next if ds.nil?

        if crit.nil?
          crit = ds.call(*v)
        else
          crit.merge!(ds.call(*v))
        end
      end
      return crit
    end

    def build_database_result
      ctx = request_context
      rel = build_database_relation
      params = request_context.params
      if params.key?(:id)
        data = rel.find(params[:id])
        ret = {success: data.present?, data: data}
      else
        data = rel.limit(ctx.limit).offset(ctx.offset).to_a
        count = rel.count
        pages_count = (count / ctx.limit.to_f).ceil
        if params.key?(:first)
          data = data.first
        elsif params.key?(:last)
          data = data.last
        end
        ret = {success: !data.nil?, data: data, count: count, pages_count: pages_count, page: ctx.page}
      end
      enhance_items(data.is_a?(Array) ? data : [data])
      return ret
    end

    def item(opts={})
      res = result(opts)
      res[:data]
    end

    def items(opts={})
      res = result(opts)
      res[:data]
    end

    def enhance_items(items)
      # use enhances here
    end

    def count
      res = result(opts)
      res[:count]
    end

    def build_result
      build_database_result
    end

    def result(opts={})
      if @result.nil? || opts[:reload]
        @result = build_result
      end
      return @result
    end

    def method_missing(method_sym, *args, &block)
      @names[method_sym.to_s] = block
    end

  end

  class ActiveRecordScopeResponder < ScopeResponder

    attr_reader :model

    def initialize(request_context, opts={}, &block)
      super(request_context, opts, &block)
      @model = opts[:model]

    end

    def base_scope
      self.model.all
    end

    def base_relation
      crit = base_scope
      incls = query_includes
      sort = query_sort
      # add includes
      if incls.present?
        crit = crit.includes(incls)
      end
      # add sort
      if sort.present?
        if crit.respond_to?(:order)
          crit = crit.order(sort)
        end
      end
      return crit
    end

    def allowed_query_includes
      # try to detect from relational model
      if model.respond_to?(:reflections)
        model.reflections.keys
      else
        []
      end
    end

    def allowed_query_sort_fields
      nil
    end

    def allowed_scope_names
      if options[:allowed_scope_names]
        ret = options[:allowed_scope_names]
      elsif model.const_defined?("PUBLIC_SCOPES")
        ret = model.const_get("PUBLIC_SCOPES")
      elsif model.respond_to?(:scope_names)
        ret = model.scope_names
      else
        ret = @names.keys
      end
      @allowed_scope_names = ret.collect(&:to_s)
    end

    def query_includes
      # go through allowed ones and see which are specified
      ta = SmartAPI.bool_tree(allowed_query_includes || [])
      ti = SmartAPI.bool_tree(request_context.includes || [])
      inter = SmartAPI.bool_tree_intersection(ta, ti)
      return SmartAPI.bool_tree_to_array(inter)
    end

    def query_sort
      # eventually use allowed_query_sort_fields
      sort = request_context.sort
      return nil if sort.blank?
      sort = sort.strip
      nsm = model.const_defined?("NAMED_SORTS") ? model.const_get("NAMED_SORTS") : {}
      # validate sort
      if (ns = nsm[sort]).present?
        # handle named sort
        sort = ns
      else
        validate_custom_sort!(sort)
      end
      return sort
    end

    def validate_custom_sort!(sort)
      parts = sort.split(/\s+/).collect(&:downcase)
      raise "Invalid sort #{sort}: Too long" if parts.length > 2
      raise "Invalid sort #{sort}: Must end with asc/desc" if parts[-1] != "asc" && parts[-1] != "desc"
    end

    def scope_for_name(name)
      asns = allowed_scope_names
      if asns && !asns.include?(name.to_s)
        return nil
      end
      return @names[name] if @names[name]
      return model.method(name.to_sym) if model.respond_to?(name.to_sym)
      return nil
    end

  end

end
