require_relative 'ops/utils'
require_relative 'assignment'

module PlanOut
  class Interpreter
    attr_accessor :experiment_salt

    def initialize(serialization, experiment_salt = 'global_salt',
                 inputs = {}, environment = nil)
      @_serialization = serialization
      @_env = if environment == nil
        Assignment.new(experiment_salt)
              else
        environment
              end
      @experiment_salt = @_experiment_salt = experiment_salt
      @_evaluated = false
      @_in_experiment = true
      @_inputs = inputs.clone
    end

    def register_operators(operators)
      PlanOutOps::Operators.registerOperators(operators)
      return self
    end

    def get_params
      # Evaluate code if it hasn't already been evaluated
      unless @_evaluated
        begin
          self.evaluate(@_serialization)
        rescue PlanOutOps::StopPlanOutException => e
          # StopPlanOutException is raised when script calls "return", which
          # short circuits execution and sets in_experiment
          @_in_experiment = e.in_experiment
        end
        @_evaluated = true
      end
      return @_env
    end

    def in_experiment
      return @_in_experiment
    end

    def salt_sep
      return @_env.salt_sep
    end

    def set_env(new_env)
      @_env = new_env.clone
      return self
    end

    def has(name)
      name = begin
               name.to_sym
             rescue
               name
             end
      return @_env.include?(name)
    end

    def get(name, default = nil)
      name = begin
               name.to_sym
             rescue
               name
             end
      return @_env.get(name, @_inputs.fetch(name, default))
    end

    def set(name, value)
      name = begin
               name.to_sym
             rescue
               name
             end
      @_env[name] = value
      return self
    end

    # Sets variables to maintain a frozen state
    def set_overrides(overrides)
      @_env.set_overrides(overrides)
      return self
    end

    def get_overrides
      return @_env.get_overrides
    end

    def has_override(name)
      name = begin
               name.to_sym
             rescue
               name
             end
      return self.get_overrides.include?(name)
    end

    def evaluate(planout_code)
      if planout_code.is_a?(Hash) && planout_code.include?(:op)
        return PlanOutOps::Operators.operatorInstance(planout_code).execute(self)
      elsif planout_code.is_a?(Array)
        return planout_code.map { |i| self.evaluate(i) }
      else
        return planout_code
      end
    end
  end
end
