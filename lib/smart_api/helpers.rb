module SmartAPI

  module Helpers

    def parse_bool(val)
      if val == true || val == "true" || val == 1
        return true
      else
        return false
      end
    end

    def parse_opts(opts)
      return nil if opts.nil?
      new_opts = opts
      if opts.is_a?(String) && !opts.blank?
        begin
          new_opts = JSON.parse(opts)
        rescue => ex
          new_opts = opts
        end
      end
      if new_opts.is_a?(Hash)
        return new_opts.with_indifferent_access
      else
        return new_opts
      end
    end

    def parse_data(opts)
      self.parse_opts(opts)
    end

    def log_exception(ex, opts={})
      Rails.logger.info ex.message
      Rails.logger.info ex.backtrace.join("\n\t")
      if defined?(ExceptionNotifier) && opts[:notify] != false
        ExceptionNotifier.notify_exception(ex, opts)
      end
    rescue => ex
      Rails.logger.info ex.message
      Rails.logger.info ex.backtrace.join("\n\t")
    end

    def bool_tree(arr)
      ret = {}
      return nil if arr.nil?
      return arr if arr.is_a?(Hash)
      arr.each do |val|
        if val.is_a?(Hash)
          val.each do |hk, hv|
            ret[hk] = self.bool_tree(hv)
          end
        else
          ret[val] = {}
        end
      end
      return ret
    end

    def bool_tree_intersection(tree1, tree2)
      ret = {}
      return nil if tree1.nil? || tree2.nil?
      tree1.each do |k, v|
        t2v = tree2[k]
        if t2v.nil?
          next
        elsif !v.empty?
          ret[k] = self.bool_tree_intersection(v, t2v)
        else
          ret[k] = {}
        end
      end
      return ret
    end

    def bool_tree_to_array(tree)
      ret = []
      tree.each do |k, v|
        if !v.empty?
          ret << {k => self.bool_tree_to_array(v)}
        else
          ret << k
        end
      end
      return ret
    end

  end

end
