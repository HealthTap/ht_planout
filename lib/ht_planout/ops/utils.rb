require 'json'
require_relative 'core'
require_relative 'random'

module PlanOutOps
  class StopPlanOutException < Exception

    def initialize(in_experiment)
      @in_experiment = in_experiment
    end

    def in_experiment
      @in_experiment
    end

  end

  class Operators

    #Singleton class for inspecting and registering operators
    @@operators = {
      "literal": Literal,
      "get": Get,
      "seq": Seq,
      "set": Set,
      "return": Return,
      "index": Index,
      "array": Array,
      "map": Map,
      "equals": Equals,
      "cond": Cond,
      "and": And,
      "or": Or,
      ">": GreaterThan,
      "<": LessThan,
      ">=": GreaterThanOrEqualTo,
      "<=": LessThanOrEqualTo,
      "%": Mod,
      "/": Divide,
      "not": Not,
      "round": Round,
      "negative": Negative,
      "min": Min,
      "max": Max,
      "length": Length,
      "coalesce": Coalesce,
      "product": Product,
      "sum": Sum,
      "randomFloat": RandomFloat,
      "randomInteger": RandomInteger,
      "bernoulliTrial": BernoulliTrial,
      "bernoulliFilter": BernoulliFilter,
      "uniformChoice": UniformChoice,
      "weightedChoice": WeightedChoice,
      "sample": Sample,
      "fastSample": FastSample
    }

    def self.registerOperators(operators)
      operators.each do |op, obj|
        raise "Opertor already registered: #{op}" if @@operators.include? op
        @@operators[op] = operators[op]
      end
    end

    def self.isOperator(op)
      return op.is_a?(Hash) && op.include?(:op)
    end

    def self.operatorInstance(params)
      op = params[:op]
      op = op.to_sym rescue op
      raise "Unknown operator: #{op}" unless @@operators.include? op
      return @@operators[op].new(params)
    end

  end
end
