require_relative 'utils'

module PlanOutOps
  class PlanOutOp
    # all PlanOut operator have some set of args that act as required and
    # optional arguments

    attr_accessor :args, :mapper

    def initialize(args)
      @args = args
    end

    def getArgMixed(name)
      raise "#{self.class}: missing argument: #{name}." unless @args.include?(name)
      return @args[name]
    end

    def getArgInt(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be an int." unless arg.respond_to?(:to_i)
      return arg
    end

    def getArgFloat(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be a float." unless arg.respond_to?(:to_f)
      return arg.to_f
    end

    def getArgString(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be an string. Not a: #{arg.class}" unless arg.respond_to?(:to_s) || arg.respond_to?(:to_sym)
      return arg
    end

    def getArgNumeric(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be a float." unless arg.respond_to?(:to_f)
      return arg
    end

    def getArgList(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be a list. Not a: #{arg}" unless arg.respond_to?(:to_a)
      return arg
    end

    def getArgMap(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be a map." unless arg.respond_to?(:to_h)
      return arg
    end

    def getArgIndexish(name)
      arg = self.getArgMixed(name)
      raise "#{self.class}: #{name} must be a map or list." unless arg.respond_to?(:to_a) || arg.respond_to?(:to_h)
      return arg
    end
  end

  # PlanOutOpSimple is the easiest way to implement simple operators.
  # The class automatically evaluates the values of all args passed in via
  # execute(), and stores the PlanOut mapper object and evaluated
  # args as instance variables.  The user can then extend PlanOutOpSimple
  # and implement simpleExecute().

  class PlanOutOpSimple < PlanOutOp
    def execute(mapper)
      @mapper = mapper
      parameter_names = @args.keys
      parameter_names.each do |param|
        @args[param] = mapper.evaluate(@args[param])
      end
      return self.simpleExecute
    end
  end

  class PlanOutOpBinary < PlanOutOpSimple
    def simpleExecute
      return self.binaryExecute(
        self.getArgMixed(:left),
        self.getArgMixed(:right))
    end
  end

  class PlanOutOpUnary < PlanOutOpSimple
      def simpleExecute
        return self.unaryExecute(self.getArgMixed(:value))
      end
  end

  class PlanOutOpCommutative < PlanOutOpSimple
    def simpleExecute
      raise 'expected argument: values' unless @args.include?(:values)
      return self.commutativeExecute(self.getArgList(:values))
    end
  end
end
