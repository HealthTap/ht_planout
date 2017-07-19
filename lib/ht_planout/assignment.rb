require_relative 'ops/base'

# The Assignment class is the main work horse that lets you to execute
# random operators using the names of variables being assigned as salts.
# It is a MutableMapping, which means it plays nice with things like Flask
# template renders.

module PlanOut
  class Assignment < Hash
    ''"
    A mutable mapping that contains the result of an assign call.
    "''

    attr_accessor :experiment_salt, :salt_sep

    def initialize(experiment_salt, overrides = {})
      @experiment_salt = experiment_salt
      @_overrides = overrides.clone
      @_data = overrides.clone
      @salt_sep = '.' # separates unit from experiment/variable salt
    end

    def evaluate(value)
      return value
    end

    def get_overrides
      return @_overrides
    end

    def set_overrides(overrides)
      @_overrides = overrides.clone
      @_overrides.each do |k, _v|
        k = begin
              k.to_sym
            rescue
              k
            end
        @_data[k] = @_overrides[k]
      end
    end

    def get(name, default = nil)
      name = begin
               name.to_sym
             rescue
               name
             end
      @_data.fetch(name, default)
    end

    def fetch(name, default = nil)
      get(name, default)
    end

    def set(name, value)
      name = begin
               name.to_sym
             rescue
               name
             end

      return if @_overrides.include?(name)

      if value.is_a? PlanOutOps::PlanOutOpRandom
        value.args[:salt] = name unless value.args.include? :salt
        @_data[name] = value.execute(self)
      else
        @_data[name] = value
      end
    end

    def [](x)
      get(x)
    end

    def []=(x, y)
      set(x, y)
    end

    def ==(other)
      other == @_data
    end

    def to_h
      @_data
    end
  end
end
