# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

require_relative 'ops/base'

# The Assignment class is the main work horse that lets you to execute
# random operators using the names of variables being assigned as salts.
# It is a MutableMapping, which means it plays nice with things like Flask
# template renders.

module PlanOut
  class Assignment < Hash

    """
    A mutable mapping that contains the result of an assign call.
    """

    attr_accessor :experiment_salt, :salt_sep

    def initialize(experiment_salt, overrides={})
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
      # maybe this should be a deep copy?
      @_overrides = overrides.clone
      @_overrides.each do |k, v|
        @_data[k] = @_overrides[k]
      end
    end

    def get(name, default=nil)
      name = name.to_sym rescue name
      if [:_data, :_overrides, :experiment_salt].include?(name) #TODO Remove this?
        return @__dict__[name]
      else
        return @_data.fetch(name, default)
      end
    end

    def fetch(name, default=nil)
      get(name, default)
    end

    def set(name, value)
      name = name.to_sym rescue name
      if [:_data, :_overrides, :salt_sep, :experiment_salt].include?(name)
        @__dict__[name] = value
        return
      end

      if @_overrides.include?(name)
        return
      end

      if value.is_a? PlanOutOps::PlanOutOpRandom
        if !value.args.include? :salt
          value.args[:salt] = name
        end
        @_data[name] = value.execute(self)
      else
        @_data[name] = value
      end
    end

    def [](x)
      get(x)
    end

    def []=(x,y)
      set(x,y)
    end

    def ==(other)
      other == @_data
    end

    def to_h
      @_data
    end

  end
end
