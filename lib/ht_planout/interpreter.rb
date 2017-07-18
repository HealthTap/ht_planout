# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

require_relative 'ops/utils'
require_relative 'assignment'

module PlanOut
  class Interpreter

    attr_accessor :experiment_salt
    """PlanOut interpreter"""

    def initialize(serialization, experiment_salt='global_salt',
                 inputs={}, environment=nil)
      @_serialization = serialization
      if environment == nil
        @_env = Assignment.new(experiment_salt)
      else
        @_env = environment
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
      """Get all assigned parameter values from an executed interpreter script"""
      # evaluate code if it hasn't already been evaluated
      if !@_evaluated
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
      """Replace the current environment with a dictionary"""
      @_env = new_env.clone
      # note that overrides are inhereted from new_env
      return self
    end

    def has(name)
      """Check if a variable exists in the PlanOut environment"""
      name = name.to_sym rescue name
      return @_env.include?(name)
    end

    def get(name, default=nil)
      """Get a variable from the PlanOut environment"""
      name = name.to_sym rescue name
      return @_env.get(name, @_inputs.fetch(name, default))
    end

    def set(name, value)
      """Set a variable in the PlanOut environment"""
      name = name.to_sym rescue name
      @_env[name] = value
      return self
    end

    def set_overrides(overrides)
      """
      Sets variables to maintain a frozen state during the interpreter's
      execution. This is useful for debugging PlanOut scripts.
      """
      @_env.set_overrides(overrides)
      return self
    end

    def get_overrides
      """Get a dictionary of all overrided values"""
      return @_env.get_overrides()
    end

    def has_override(name)
      """Check to see if a variable has an override."""
      name = name.to_sym rescue name
      return self.get_overrides().include?(name)
    end

    def evaluate(planout_code)
      """Recursively evaluate PlanOut interpreter code"""
      # if the object is a PlanOut operator, execute it it.
      if planout_code.is_a?(Hash) && planout_code.include?(:op)
        return PlanOutOps::Operators.operatorInstance(planout_code).execute(self)
      # if the object is a list, iterate over the list and evaluate each
      # element
      elsif planout_code.is_a?(Array)
        return planout_code.map { |i| self.evaluate(i) }
      else
        return planout_code  # data is a literal
      end
    end

  end
end
