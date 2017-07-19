require_relative 'base'
require_relative 'utils'

module PlanOutOps
  class Literal < PlanOutOp
    def execute(mapper)
      return self.getArgMixed(:value)
    end
  end

  class Get < PlanOutOp
    def execute(mapper)
      return mapper.get(self.getArgString(:var))
    end
  end

  class Seq < PlanOutOp
    def execute(mapper)
      self.getArgList(:seq).each do |op|
        mapper.evaluate(op)
      end
    end
  end

  class Set < PlanOutOp
    def execute(mapper)
      var, value = self.getArgString(:var), self.getArgMixed(:value)
      return if mapper.has_override(var)

      # if the value is operator, add the name of the variable as a salt if no
      # salt is provided.
      if Operators.isOperator(value) && !value.include?(:salt)
        value[:salt] = var
      end

      # if we are setting the special variable, experiment_salt, update mapper
      # object accordingly with the new experiment-level salt
      mapper.experiment_salt = value if var == :experiment_salt

      mapper.set(var, mapper.evaluate(value))
    end
  end

  class Return < PlanOutOp
    def execute(mapper)
      # if script calls return; or return();, assume the unit is in the
      # experiment
      value = mapper.evaluate(self.getArgMixed(:value))
      in_experiment = value ? true : false
      raise StopPlanOutException.new(in_experiment)
    end
  end

  class Array < PlanOutOp
      def execute(mapper)
        return self.getArgList(:values).map {|value| mapper.evaluate(value)}
      end
  end

  class Map < PlanOutOpSimple
      def simpleExecute
        m = {}.merge(@args)
        m.delete(:op)
        m.delete(:salt)
        return m
      end
  end

  class Coalesce < PlanOutOp
      def execute(mapper)
        self.getArgList(:values).each do |x|
          eval_x = mapper.evaluate(x)
          return eval_x unless eval_x.nil?
        end
        return nil
      end
  end

  class Index < PlanOutOpSimple
    def simpleExecute
      # returns value at index if it exists, returns nil otherwise.
      # works with both lists and dictionaries.
      base, index = self.getArgIndexish(:base), self.getArgMixed(:index)
      if base.is_a? Array
        if index >= 0 && index < base.length
            return base[index]
        else
          return nil
        end
      else
        # assume we have a dictionary
        index = begin
                  index.to_sym
                rescue
                  index
                end
        return base.fetch(index, nil)
      end
      return self.getArgIndexish(:base)[self.getArgMixed(:index)]
    end
  end

  class Cond < PlanOutOp
    def execute(mapper)
      self.getArgList(:cond).each do |i|
        if_clause, then_clause = i[:if], i[:then]
        return mapper.evaluate(then_clause) if mapper.evaluate(if_clause)
      end
    end
  end

  class And < PlanOutOp
    def execute(mapper)
      self.getArgList(:values).each do |clause|
        return false unless mapper.evaluate(clause)
      end
      return true
    end
  end

  class Or < PlanOutOp
    def execute(mapper)
      self.getArgList(:values).each do |clause|
        return true if mapper.evaluate(clause)
      end
      return false
    end
  end

  class Product < PlanOutOpCommutative
    def commutativeExecute(values)
      return values.inject {|x, y| x * y }
    end
  end

  class Sum < PlanOutOpCommutative
    def commutativeExecute(values)
      return values.inject(0, :+)
    end
  end

  class Equals < PlanOutOpBinary
    def getInfixString
      return '=='
    end

    def binaryExecute(left, right)
      return left == right
    end
  end

  class GreaterThan < PlanOutOpBinary
    def binaryExecute(left, right)
      return left > right
    end
  end

  class LessThan < PlanOutOpBinary
    def binaryExecute(left, right)
      return left < right
    end
  end

  class LessThanOrEqualTo < PlanOutOpBinary
    def binaryExecute(left, right)
      return left <= right
    end
  end

  class GreaterThanOrEqualTo < PlanOutOpBinary
    def binaryExecute(left, right)
      return left >= right
    end
  end

  class Mod < PlanOutOpBinary
    def binaryExecute(left, right)
      return left % right
    end
  end

  class Divide < PlanOutOpBinary
    def binaryExecute(left, right)
      return left.to_f / right.to_f
    end
  end

  class Round < PlanOutOpUnary
    def unaryExecute(value)
      return round(value)
    end
  end

  class Not < PlanOutOpUnary
    def unaryExecute(value)
      return !value
    end
  end

  class Negative < PlanOutOpUnary
      def unaryExecute(value)
        return 0 - value
      end
  end

  class Min < PlanOutOpCommutative
    def commutativeExecute(values)
      return values.min
    end
  end

  class Max < PlanOutOpCommutative
    def commutativeExecute(values)
      return values.max
    end
  end

  class Length < PlanOutOpUnary
    def unaryExecute(value)
      return value.length
    end
  end
end
