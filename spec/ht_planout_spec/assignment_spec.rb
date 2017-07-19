RSpec.describe "Assignment Test" do
  tester_unit = 4
  tester_salt = 'test_salt'

  it 'set_get_constant' do
    a = PlanOut::Assignment.new(tester_salt)
    a[:foo] = 12
    expect(a[:foo]).to eq(12)
  end

  it 'set_get_uniform' do
    a = PlanOut::Assignment.new(tester_salt)
    a[:foo] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: tester_unit)
    a[:bar] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: tester_unit)
    a[:baz] = PlanOutOps::UniformChoice.new(choices: ['a', 'b'], unit: tester_unit)
    expect(a[:foo]).to eq('b')
    expect(a[:bar]).to eq('a')
    expect(a[:baz]).to eq('a')
  end

  it 'overrides' do
    a = PlanOut::Assignment.new(tester_salt)
    a.set_overrides({'x': 42, 'y': 43})
    a[:x] = 5
    a[:y] = 6
    expect(a[:x]).to eq(42)
    expect(a[:y]).to eq(43)
  end

  it 'custom_salt' do
    a = PlanOut::Assignment.new(tester_salt)
    custom_salt = lambda { |x,y| "#{x}-#{y}" }
    a[:foo] = PlanOutOps::UniformChoice.new(choices: (0..7).to_a, unit: tester_unit)
    expect(a[:foo]).to eq(7)
  end
end
