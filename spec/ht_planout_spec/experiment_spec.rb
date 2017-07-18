# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

require 'json'


$global_log = []

RSpec.describe "Experiment Test" do

  def experiment_tester(exp_class, in_experiment=true)
    $global_log = []

    e = exp_class.new(i: 42)
    e.set_overrides({'bar': 42})
    params = e.get_params()

    expect(params.include? :foo).to be_truthy
    expect(params[:foo]).to eq('b')

    # test to make sure overrides work correctly
    expect(params[:bar]).to eq(42)

    # log should only have one entry, and should contain i as an input
    # and foo and bar as parameters
    if in_experiment
      expect($global_log.length).to eq(1)
      validate_log($global_log[0], {
        'inputs': {'i': nil},
        'params': {'foo': nil, 'bar': nil}
      })
    else
      expect($global_log.length).to eq(0)
    end

    # test to make sure experiment eligibility works correctly
    expect(e.in_experiment).to eq(in_experiment)
  end

  def validate_log(blob, expected_fields)
      # Expected field is a dictionary containing all of the expected keys
    # in the expected structure. Key values are ignored.
    expected_fields.each do |field, value|
      expect(blob.include? field).to be_truthy
      if value.class == Hash
        expect(validate_log(blob[field], value)).to be_truthy
      else
        expect(blob.include? field).to be_truthy
      end
    end
  end

  it 'vanilla_experiment' do
    class TestVanillaExperiment < PlanOut::Experiment

      def configure_logger
      end

      def log(stuff)
        $global_log.push(stuff)
      end

      def previously_logged
      end

      def setup
        self.name = 'test_name'
      end

      def assign(params, i:)
        params[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: i)
      end
    end
    experiment_tester(TestVanillaExperiment)
  end

  it 'vanilla_experiment_disabled' do
    class TestVanillaExperiment < PlanOut::Experiment

      def configure_logger
      end

      def log(stuff)
        $global_log.push(stuff)
      end

      def previously_logged
      end

      def setup
        self.name = 'test_name'
      end

      def assign(params, i:)
        params[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: i)
        return false
      end
    end

    experiment_tester(TestVanillaExperiment, false)
  end

  # makes sure assignment only happens once
  it 'single_assignment' do
    class TestSingleAssignment < PlanOut::Experiment

      def configure_logger
      end

      def log(stuff)
        $global_log.push(stuff)
      end

      def previously_logged
      end

      def setup
        self.name = 'test_name'
      end

      def assign(params, i:, counter:)
        params[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: i)
        counter[:count] = counter.fetch(:count, 0) + 1
      end
    end

    assignment_count = {count: 0}
    e = TestSingleAssignment.new(i: 10, counter: assignment_count)
    expect(assignment_count[:count]).to eq(0)
    e.get('foo')
    expect(assignment_count[:count]).to eq(1)
    e.get('foo')
    expect(assignment_count[:count]).to eq(1)
  end

  it 'interpreted_experiment' do
    class TestInterpretedExperiment < PlanOut::SimpleInterpretedExperiment

      def log(stuff)
        $global_log.push(stuff)
      end

      def loadScript
        @script = {"op":"seq",
           "seq": [
            {"op":"set",
             "var":"foo",
             "value":{
               "choices":["a","b"],
               "op":"uniformChoice",
               "unit": {"op": "get", "var": "i"}
               }
            },
            {"op":"set",
             "var":"bar",
             "value": 41
            }
         ]}
      end
    end

    experiment_tester(TestInterpretedExperiment)
  end

  it 'disabled_interpreted_experiment' do
    class TestInterpretedDisabled < PlanOut::SimpleInterpretedExperiment
      def log(stuff)
        $global_log.push(stuff)
      end

      def loadScript
        @script = {
         "op": "seq",
         "seq": [
          {
           "op": "set",
           "var": "foo",
           "value": "b"
          },
          {
           "op": "return",
           "value": false
          }
         ]
        }
      end
    end
    experiment_tester(TestInterpretedDisabled, false)
  end


  it 'short_circuit_exposure_logging' do
    class TestNoExposure < PlanOut::Experiment

      def configure_logger
      end

      def log(stuff)
        $global_log.push(stuff)
      end

      def previously_logged
      end

      def setup
        self.name = 'test_name'
      end

      def assign(params, i:)
        params[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: i)
        return false
      end
    end

    experiment_tester(TestNoExposure, false)

    class TestNoExposure < PlanOut::Experiment

      def configure_logger
      end

      def log(stuff)
        $global_log.push(stuff)
      end

      def previously_logged
      end

      def setup
        self.name = 'test_name'
      end

      def assign(params, i:)
        params[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: i)
        return true
      end

    end

    experiment_tester(TestNoExposure, true)
  end

  it 'demo_production_experiment' do
    class TestDemoProductionExperiment < PlanOut::ProductionExperiment
      def configure_logger
      end

      def log(stuff)
        $global_log.push(stuff)
      end

      def previously_logged
      end

      def setup
        self.name = 'test_name'
      end

      def assign(params, i:)
        params[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: i)
      end

      def get_param_names
        return [:foo]
      end
    end

    $global_log = []
    e = TestDemoProductionExperiment.new(i: 42)
    expect(e.get('nobar')).to eq(nil)
    expect($global_log.length).to eq(0)
    expect(e.get('foo')).to eq('b')
    expect($global_log.length).to eq(1)
  end

end
