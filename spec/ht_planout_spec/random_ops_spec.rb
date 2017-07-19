RSpec.describe 'Test Random Operators' do
  # z_{\alpha/2} for \alpha=0.001, e.g., 99.9% CI: qnorm(1-(0.001/2))
  Z = 3.29

  # decorator for quickly constructing PlanOutKit experiments

  def experiment_decorator(name)
    wrap = lambda do |f|
      wrapped_f = lambda do |args|
        params = PlanOut::Assignment.new(name)
        return f.call(params, args)
      end
      return wrapped_f
    end
    return wrap
  end

  def valueMassToDensity(value_mass)
    values = value_mass.map{ |l| l[0]}
    ns = value_mass.map{ |l| l[1]}
    ns_sum = Float(ns.reduce(:+))
    value_density = values.zip(ns.map{|i| i / ns_sum}).to_h
    return value_density
  end

  def distributionTester(func, value_mass, n = 1000)
    # run n trials of f() with input i
    xs = (0..n - 1).map{|i| func.call(i: i).get(:x)}
    value_density = valueMassToDensity(value_mass)

    # test outcome frequencies against expected density
    assertProbs(xs, value_density, Float(n))
  end

  def assertProbs(xs, value_density, n)
    hist = Hash.new(0)
    xs.each { |el| hist[el] += 1 }

    # do binomial test of proportions for each item
    hist.each do |k, _v|
      assertProp(hist[k] / n, value_density[k], n)
    end
  end

  def assertProp(observed_p, expected_p, n)
    # normal approximation of binomial CI.
    # this should be OK for large n and values of p not too close to 0 or
    # 1.
    se = Z * Math.sqrt(expected_p * (1 - expected_p) / n)
    expect((observed_p - expected_p).abs <= se).to be_truthy
  end

  it 'salt' do
    i = 20
    a = PlanOut::Assignment.new('assign_salt_a')

    # assigning variables with different names and the same unit should yield
    # different randomizations, when salts are not explicitly specified
    a[:x] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i)
    a[:y] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i)
    expect(a[:x] != a[:y]).to be_truthy

    # when salts are specified, they act the same way auto-salting does
    a[:z] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i, salt: 'x')
    expect(a[:x] == a[:z]).to be_truthy

    # when the Assignment-level salt is different, variables with the same
    # name (or salt) should generally be assigned to different values
    b = PlanOut::Assignment.new('assign_salt_b')
    b[:x] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i)
    expect(a[:x] != b[:x]).to be_truthy

    # when a full salt is specified, only the full salt is used to do
    # hashing
    a[:f] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i, full_salt: 'fs')
    b[:f] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i, full_salt: 'fs')
    expect(a[:f] == b[:f]).to be_truthy
    a[:f] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i, full_salt: 'fs2')
    b[:f] = PlanOutOps::RandomInteger.new(min: 0, max: 100000, unit: i, full_salt: 'fs2')
    expect(a[:f] == b[:f]).to be_truthy
  end

  it 'bernoulli' do
    # returns experiment function with x = BernoulliTrial(p) draw
    # experiment salt is p
    def bernoulliTrial(p)
      exp_func = lambda do |e, i|
        e[:x] = PlanOutOps::BernoulliTrial.new(p: p, unit: i)
        return e
      end
      return experiment_decorator(p).call(exp_func)
    end

    distributionTester(bernoulliTrial(0.0), [[0, 1], [1, 0]])
    distributionTester(bernoulliTrial(0.1), [[0, 0.9], [1, 0.1]])
    distributionTester(bernoulliTrial(1.0), [[0, 0], [1, 1]])
  end

  it 'uniform choice' do
    # returns experiment function with x = UniformChoice(c) draw
    # experiment salt is a string version of c
    def uniformChoice(c)
      str_c = c.map{ |el| el.to_s }.join(',')

      exp_func = lambda do |e, i|
        e[:x] = PlanOutOps::UniformChoice.new(choices: c, unit: i)
        return e
      end
      return experiment_decorator(str_c).call(exp_func)
    end

    distributionTester(uniformChoice(['a']), [['a', 1]])
    distributionTester(
      uniformChoice(%w[a b]), [['a', 1], ['b', 1]])
    distributionTester(
      uniformChoice([1, 2, 3, 4]), [[1, 1], [2, 1], [3, 1], [4, 1]])
  end

  it 'weighted choice' do
    # returns experiment function with x = WeightedChoice(c,w) draw
    # experiment salt is a string version of weighted_dict's keys
    def weightedChoice(weight_pairs)
      c = weight_pairs.map{ |l| l[0]}
      w = weight_pairs.map{ |l| l[1]}
      exp_func = lambda do |e, i|
        e[:x] = PlanOutOps::WeightedChoice.new(choices: c, weights: w, unit: i)
        return e
      end
      return experiment_decorator(w.map{|el| el.to_s}.join(',')).call(exp_func)
    end

    d = [['a', 1]]
    distributionTester(weightedChoice(d), d)
    d = [['a', 1], ['b', 2]]
    distributionTester(weightedChoice(d), d)
    d = [['a', 0], ['b', 2], ['c', 0]]
    distributionTester(weightedChoice(d), d)

    # we should be able to repeat the same choice multiple times
    # in weightedChoice(). in this case we repeat 'a'.
    da = [['a', 1], ['b', 2], ['c', 0], ['a', 2]]
    db = [['a', 3], ['b', 2], ['c', 0]]
    distributionTester(weightedChoice(da), db)
  end

  it 'sample' do
    # returns experiment function with x = sample(c, draws)
    # experiment salt is a string version of c
    def sample(choices, draws, fast_sample = false)
      exp_func = lambda do |e, i|
        e[:x] = if fast_sample
          PlanOutOps::FastSample.new(choices: choices, draws: draws, unit: i)
                else
          PlanOutOps::Sample.new(choices: choices, draws: draws, unit: i)
                end
        expect(e[:x].length == draws).to be_truthy
        return e
      end
      return experiment_decorator(choices.map{|el| el.to_s}.join(',')).call(exp_func)
    end

    def listDistributionTester(func, value_mass, n = 1000)
      value_density = valueMassToDensity(value_mass)
      # compute n trials
      xs_list = (0..n - 1).map{|i| func.call(i: i).get(:x)}

      # each xs is a row of the transpose of xs_list.
      # this is expected to have the same distribution as value_density
      xs_list.transpose.each do |xs|
        assertProbs(xs, value_density, Float(n))
      end
    end

    listDistributionTester(
      sample([1, 2, 3], draws = 3), [[1, 1], [2, 1], [3, 1]])
    listDistributionTester(
      sample([1, 2, 3], draws = 2), [[1, 1], [2, 1], [3, 1]])
    listDistributionTester(
      sample([1, 2, 3], draws = 2, fast_sample = true), [[1, 1], [2, 1], [3, 1]])
    listDistributionTester(
      sample(%w[a a b], draws = 3), [['a', 2], ['b', 1]])

    a = PlanOut::Assignment.new('assign_salt_a')
    a[:old_sample] = PlanOutOps::Sample.new(choices: [1, 2, 3, 4], draws: 1, unit: 1)
    new_sample = a[:old_sample]
    a[:old_sample] = PlanOutOps::FastSample.new(choices: [1, 2, 3, 4], draws: 1, unit: 1)
    expect(a[:old_sample].length == 1).to be_truthy
    expect(new_sample.length == 1).to be_truthy
    expect(a[:old_sample] != new_sample).to be_truthy
  end
end
