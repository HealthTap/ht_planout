require_relative 'base'

module PlanOutOps
  class PlanOutOpRandom < PlanOutOpSimple
    LONG_SCALE = Float(0xFFFFFFFFFFFFFFF)

    def getUnit(appended_unit = nil)
      unit = self.getArgMixed(:unit)
      unit = [unit] if unit.class != Object::Array
      unit += [appended_unit] unless appended_unit.nil?
      return unit
    end

    def getHash(appended_unit = nil)
      full_salt = if self.args.include? :full_salt
        self.getArgString(:full_salt) + '.' # do typechecking
                  else
        "#{self.mapper.experiment_salt}.#{self.getArgString(:salt)}#{self.mapper.salt_sep}"
                  end
      unit_str = self.getUnit(appended_unit).map { |el| el.to_s }.join('.')
      hash_str = "#{full_salt}#{unit_str}"
      Digest::SHA1.hexdigest(hash_str)[0..14].to_i(16)
    end

    def getUniform(min_val = 0.0, max_val = 1.0, appended_unit = nil)
      zero_to_one = self.getHash(appended_unit) / LONG_SCALE
      return min_val + (max_val - min_val) * zero_to_one
    end
  end

  class RandomFloat < PlanOutOpRandom
    def simpleExecute
      min_val = self.getArgFloat(:min)
      max_val = self.getArgFloat(:max)

      return self.getUniform(min_val, max_val)
    end
  end

  class RandomInteger < PlanOutOpRandom
    def simpleExecute
      min_val = self.getArgInt(:min)
      max_val = self.getArgInt(:max)

      return min_val + self.getHash % (max_val - min_val + 1)
    end
  end

  class BernoulliTrial < PlanOutOpRandom
    def simpleExecute
      p = self.getArgNumeric(:p)
      raise "#{self.class}: p must be a number between 0.0 and 1.0, not #{p}!" unless p >= 0 && p <= 1.0
      rand_val = self.getUniform(0.0, 1.0)
      rand_val <= p ? 1 : 0
    end
  end

  class BernoulliFilter < PlanOutOpRandom
    def simpleExecute
      p = self.getArgNumeric(:p)
      values = self.getArgList(:choices)
      raise "#{self.class}: p must be a number between 0.0 and 1.0, not #{p}!" unless p >= 0 && p <= 1.0
      return [] if values.length == 0
      values.map {|i| self.getUniform(0.0, 1.0, i) <= p ? i : nil}.compact
    end
  end

  class UniformChoice < PlanOutOpRandom
    def simpleExecute
      choices = self.getArgList(:choices)

      return [] if choices.length == 0
      rand_index = self.getHash % choices.length
      return choices[rand_index]
    end
  end

  class WeightedChoice < PlanOutOpRandom
    def simpleExecute
      choices = self.getArgList(:choices)
      weights = self.getArgList(:weights)

      return [] if choices.length == 0

      cum_weights = Object::Array.new(weights.length)
      cum_sum = 0.0

      weights.each_with_index do |weight, index|
        cum_sum += weight
        cum_weights[index] = cum_sum
      end

      stop_value = self.getUniform(0.0, cum_sum)
      cum_weights.each_with_index do |cum_weight, index|
        return choices[index] if stop_value <= cum_weight
      end
    end
  end

  class BaseSample < PlanOutOpRandom
    def copyChoices
      self.getArgList(:choices).map { |x| x }
    end

    def getNumDraws(choices)
      if self.args.include? :draws
        num_draws = self.getArgInt(:draws)
        raise "#{self.class}: cannot make #{num_draws} draws when only #{choices.length} choices are available" unless num_draws <= choices.length
        return num_draws
      else
        return choices.length
      end
    end
  end

  class FastSample < BaseSample
    def simpleExecute
      choices = self.copyChoices
      num_draws = self.getNumDraws(choices)
      stopping_point = choices.length - num_draws

      (choices.length - 1).downto(1).each do |i|
        j = self.getHash(i) % (i + 1)
        choices[i], choices[j] = choices[j], choices[i]
        return choices[i..-1] if stopping_point == i
      end
      return choices[0..num_draws - 1]
    end
  end

  class Sample < BaseSample
    def simpleExecute
      choices = self.copyChoices
      num_draws = self.getNumDraws(choices)

      (choices.length - 1).downto(1).each do |i|
        j = self.getHash(i) % (i + 1)
        choices[i], choices[j] = choices[j], choices[i]
      end
      return choices[0..num_draws - 1]
    end
  end
end
