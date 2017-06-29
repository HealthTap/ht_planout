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
      #assert name in self.args, \
      #    "%s: missing argument: %s." % (self.__class__, name)
      return @args[name]
    end

    def getArgInt(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, six.integer_types), \
      #    "%s: %s must be an int." % (self.__class__, name)
      return arg
    end

    def getArgFloat(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, (six.integer_types, float)), \
      #    "%s: %s must be a number." % (self.__class__, name)
      return Float(arg)
    end

    def getArgString(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, six.string_types), \
      #    "%s: %s must be a string." % (self.__class__, name)
      return arg
    end

    def getArgNumeric(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, (six.integer_types, float)), \
      #    "%s: %s must be a numeric." % (self.__class__, name)
      return arg
    end

    def getArgList(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, (list, tuple)), \
      #    "%s: %s must be a list." % (self.__class__, name)
      return arg
    end

    def getArgMap(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, dict), \
      #    "%s: %s must be a map." % (self.__class__, name)
      return arg
    end

    def getArgIndexish(name)
      arg = self.getArgMixed(name)
      #assert isinstance(arg, (dict, list, tuple)), \
      #    "%s: %s must be a map or list." % (self.__class__, name)
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
      parameter_names = @args.keys()
      parameter_names.each do |param|
        @args[param] = mapper.evaluate(@args[param])
      end
      return self.simpleExecute()
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
      #assert (:values in self.args), "expected argument :values"
      return self.commutativeExecute(self.getArgList(:values))
    end

  end
end
