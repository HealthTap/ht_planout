# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

RSpec.describe "Test Core Ops" do

  def runConfig(config, init={})
    e = nil
    e = PlanOut::Interpreter.new(config, 'test_salt', init)
    return e.get_params()
  end

  def run_config_single(config)
    x_config = {'op': 'set', 'var': 'x', 'value': config}
    return runConfig(x_config)[:x]
  end

  it "sets" do
    """Test setter"""
    # returns experiment object with probability p
    c = {'op': 'set', 'value': 'x_val', 'var': 'x'}
    d = runConfig(c)
    expect(d).to eq({'x': 'x_val'})
  end

  it "sequence" do
    """Test sequence"""
    config = {'op': 'seq', 'seq': [
        {'op': 'set', 'value': 'x_val', 'var': 'x'},
        {'op': 'set', 'value': 'y_val', 'var': 'y'}
    ]}
    d = runConfig(config)
    expect(d).to eq({'x': 'x_val', 'y': 'y_val'})
  end

  it "array" do
    arr = [4, 5, 'a']
    a = run_config_single({'op': 'array', 'values': arr})
    expect(a).to eq(arr)
  end

  it "map" do
    my_map = {'a': 2, 'b': 'c', 'd': false}
    m = run_config_single({'op': 'map', 'a': 2, 'b': 'c', 'd': false})
    expect(m).to eq(my_map)

    my_map = {}
    m = run_config_single({'op': 'map'})
    expect(m).to eq(my_map)
  end

  it "condition" do
    def getInput (i, r)
      {'op': 'equals', 'left': i, 'right': r}
    end
    def testIf(i)
      runConfig({
          'op': 'cond',
          'cond': [
              {'if': getInput(i, 0),
               'then': {'op': 'set', 'var': 'x', 'value': 'x_0'}},
              {'if': getInput(i, 1),
               'then': {'op': 'set', 'var': 'x', 'value': 'x_1'}}
          ]
      })
    end
    expect(testIf(0)).to eq({'x': 'x_0'})
    expect(testIf(1)).to eq({'x': 'x_1'})
  end

  it "get" do
    d = runConfig({
        'op': 'seq',
        'seq': [
            {'op': 'set', 'var': 'x', 'value': 'x_val'},
            {'op': 'set', 'var': 'y', 'value': {'op': 'get', 'var': 'x'}}
        ]
    })
    expect(d).to eq({'x': 'x_val', 'y': 'x_val'})
  end

  it "index" do
    array_literal = [10, 20, 30]
    dict_literal = {'a': 42, 'b': 43}

    # basic indexing works with array literals
    x = run_config_single(
        {'op': 'index', 'index': 0, 'base': array_literal}
    )
    expect(x).to eq(10)

    x = run_config_single(
        {'op': 'index', 'index': 2, 'base': array_literal}
    )
    expect(x).to eq(30)

    # basic indexing works with dictionary literals
    x = run_config_single(
        {'op': 'index', 'index': 'a', 'base': dict_literal}
    )
    expect(x).to eq(42)

    # invalid indexes are mapped to nil
    x = run_config_single(
        {'op': 'index', 'index': 6, 'base': array_literal}
    )
    expect(x).to eq(nil)

    # invalid indexes are mapped to nil
    x = run_config_single(
        {'op': 'index', 'index': 'c', 'base': dict_literal}
    )
    expect(x).to eq(nil)

    # non literals also work
    x = run_config_single({
        'op': 'index',
        'index': 2,
        'base': {'op': 'array', 'values': array_literal}
    })
    expect(x).to eq(30)
  end

  it "coalesce" do
    x = run_config_single({'op': 'coalesce', 'values': [nil]})
    expect(x).to eq(nil)

    x = run_config_single(
        {'op': 'coalesce', 'values': [nil, 42, nil]})
    expect(x).to eq(42)

    x = run_config_single(
        {'op': 'coalesce', 'values': [nil, nil, 43]})
    expect(x).to eq(43)
  end

  it "length" do
    arr = (0..4).to_a
    length_test = run_config_single({'op': 'length', 'value': arr})
    expect(length_test).to eq(arr.length)
    length_test = run_config_single({'op': 'length', 'value': []})
    expect(length_test).to eq(0)
    length_test = run_config_single({'op': 'length', 'value':
                                    {'op': 'array', 'values': arr}
                                    })
    expect(length_test).to eq(arr.length)
  end

  it "not" do
    # test not
    #x = run_config_single({'op': 'not', 'value': 0}) #Works in python not ruby
    #expect(x).to eq(true)
    x = run_config_single({'op': 'not', 'value': false})
    expect(x).to eq(true)

    x = run_config_single({'op': 'not', 'value': 1})
    expect(x).to eq(false)
    x = run_config_single({'op': 'not', 'value': true})
    expect(x).to eq(false)
  end

  it "or" do
    x = run_config_single({
      'op': 'or',
      'values': [false, false, false]})
    expect(x).to eq(false)

    x = run_config_single({
      'op': 'or',
      'values': [false, false, true]})
    expect(x).to eq(true)

    x = run_config_single({
      'op': 'or',
      'values': [false, true, false]})
    expect(x).to eq(true)
  end

  it "and" do
    x = run_config_single({
      'op': 'and',
      'values': [true, true, false]})
    expect(x).to eq(false)

    x = run_config_single({
      'op': 'and',
      'values': [false, false, true]})
    expect(x).to eq(false)

    x = run_config_single({
      'op': 'and',
      'values': [true, true, true]})
    expect(x).to eq(true)
  end

  it "communicative" do
    # test commutative arithmetic operators
    arr = [33, 7, 18, 21, -3]

    min_test = run_config_single({'op': 'min', 'values': arr})
    expect(min_test).to eq(arr.min)

    max_test = run_config_single({'op': 'max', 'values': arr})
    expect(max_test).to eq(arr.max)

    sum_test = run_config_single({'op': 'sum', 'values': arr})
    expect(sum_test).to eq(arr.inject(0, :+))

    product_test = run_config_single({'op': 'product', 'values': arr})
    expect(product_test).to eq(arr.inject {|x, y| x * y})
  end

  it "binary ops" do
    eq = run_config_single({'op': 'equals', 'left': 1, 'right': 2})
    expect(eq).to eq(1 == 2)
    eq = run_config_single({'op': 'equals', 'left': 2, 'right': 2})
    expect(eq).to eq(2 == 2)
    gt = run_config_single({'op': '>', 'left': 1, 'right': 2})
    expect(gt).to eq(1 > 2)
    gt = run_config_single({'op': '>', 'left': 0, 'right': 0})
    expect(gt).to eq(0 > 0)
    gt = run_config_single({'op': '>', 'left': 2, 'right': 1})
    expect(gt).to eq(2 > 1)
    lt = run_config_single({'op': '<', 'left': 1, 'right': 2})
    expect(lt).to eq(1 < 2)
    gte = run_config_single({'op': '>=', 'left': 2, 'right': 2})
    expect(gte).to eq(2 >= 2)
    gte = run_config_single({'op': '>=', 'left': 1, 'right': 2})
    expect(gte).to eq(1 >= 2)
    lte = run_config_single({'op': '<=', 'left': 2, 'right': 2})
    expect(lte).to eq(2 <= 2)
    mod = run_config_single({'op': '%', 'left': 11, 'right': 3})
    expect(mod).to eq(11 % 3)
    div = run_config_single({'op': '/', 'left': 3, 'right': 4})
    expect(div).to eq(0.75)
  end

  it "return" do
    def return_runner(return_value)
      config = {
        "op": "seq",
        "seq": [
          {
            "op": "set",
            "var": "x",
            "value": 2
          },
          {
            "op": "return",
            "value": return_value
          },
          {
            "op": "set",
            "var": "y",
            "value": 4
          }
        ]
      }
      e = PlanOut::Interpreter.new(config, 'test_salt')
      return e
    end
    i = return_runner(true)
    expect(i.get_params()).to eq({'x': 2})
    expect(i.in_experiment).to eq(true)
    i = return_runner(42)
    expect(i.get_params()).to eq({'x': 2})
    expect(i.in_experiment).to eq(true)
    i = return_runner(false)
    expect(i.get_params()).to eq({'x': 2})
    expect(i.in_experiment).to eq(false)
    i = return_runner(nil)
    expect(i.get_params()).to eq({'x': 2})
    expect(i.in_experiment).to eq(false)
  end

end
