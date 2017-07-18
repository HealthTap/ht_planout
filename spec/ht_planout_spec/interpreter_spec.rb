# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.


RSpec.describe "Test Interpreter" do
    compiled = {"op":"seq","seq":[{"op":"set","var":"group_size","value":{"choices":{"op":"array","values":[1,10]},"unit":{"op":"get","var":"userid"},"op":"uniformChoice"}},{"op":"set","var":"specific_goal","value":{"p":0.8,"unit":{"op":"get","var":"userid"},"op":"bernoulliTrial"}},{"op":"cond","cond":[{"if":{"op":"get","var":"specific_goal"},"then":{"op":"seq","seq":[{"op":"set","var":"ratings_per_user_goal","value":{"choices":{"op":"array","values":[8,16,32,64]},"unit":{"op":"get","var":"userid"},"op":"uniformChoice"}},{"op":"set","var":"ratings_goal","value":{"op":"product","values":[{"op":"get","var":"group_size"},{"op":"get","var":"ratings_per_user_goal"}]}}]}}]}]}

    interpreter_salt = 'foo'

    it 'interpreter' do
      i = PlanOut::Interpreter.new(
          compiled, interpreter_salt, {'userid': 123454})
      params = i.get_params()
      puts params.get('userid')
      expect(i.get_params().fetch('specific_goal')).to eq(1)
      expect(i.get_params().fetch('ratings_goal')).to eq(320)
    end

    it 'overrides' do
      # test overriding a parameter that gets set by the experiment
      i = PlanOut::Interpreter.new(
          compiled, interpreter_salt, {'userid': 123454})
      i.set_overrides({'group_size': 0,'specific_goal': nil})
      expect(i.get_params().fetch('specific_goal')).to eq(nil)
      expect(i.get_params().fetch('ratings_goal')).to eq(nil)

      # test to make sure input data can also be overridden
      i = PlanOut::Interpreter.new(
          compiled, interpreter_salt, {'userid': 123453})
      i.set_overrides({'userid': 123454})
      expect(i.get_params().fetch('specific_goal')).to eq(1)
    end

    it 'register_ops' do
      class CustomOp < PlanOutOps::PlanOutOpCommutative
        def commutativeExecute(values)
          return values.inject(0, :+)
        end
      end

      custom_op_script = {"op":"seq","seq":[{"op":"set","var":"x","value":{"values":[2,4],"op":"customOp"}}]}
      i = PlanOut::Interpreter.new(
          custom_op_script, interpreter_salt, {'userid': 123454})

      i.register_operators({'customOp': CustomOp})
      expect(i.get_params().fetch(:x)).to eq(6)
    end

end
