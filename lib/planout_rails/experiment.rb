# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

require 'json'
require_relative 'interpreter'

module PlanOut

  class Experiment

    attr_accessor :inputs

    logger_configured = false

    def initialize(inputs)
      @inputs = inputs           # input data

      # true when assignments have been exposure logged
      @_exposure_logged = false
      @_salt = nil              # Experiment-level salt

      # Determines whether or not exposure should be logged
      @_in_experiment = true

      # use the name of the class as the default name
      @_name = self.class.name

      # auto-exposure logging is enabled by default
      @_auto_exposure_log = true

      setup()                   # sets name, salt, etc.

      @_assignment = Assignment.new(salt)
      @_assigned = false
    end

    def _assign
      #Assignment and setup that only happens when we need to log data
      configure_logger()  # sets up loggers

      #consumers can optionally return false from assign if they don't want exposure to be logged
      assign_val = assign(@_assignment, **@inputs)
      @_in_experiment = assign_val || assign_val == nil ? true : false
      @_checksum = checksum()
      @_assigned = true
    end

    def setup
      #Set experiment attributes, e.g., experiment name and salt.
      # If the experiment name is not specified, just use the class name
    end

    def set_overrides(value)
      #Sets variables that are to remain fixed during execution.
      # note that setting this will overwrite inputs to the experiment
      @_assignment.set_overrides(value)
      o = @_assignment.get_overrides()
      o.each do |var|
        if @inputs.include? var
          @inputs[var] = o[var]
        end
      end
    end

    def in_experiment
      return @_in_experiment
    end

    def salt
      # use the experiment name as the salt if the salt is not set
      return @_salt ? @_salt : name
    end

    def salt=(value)
      @_salt = value
      if defined? @_assignment
        @_assignment.experiment_salt = value
      end
    end

    def name
      return @_name
    end

    def name=(value)
      @_name = value.gsub(/\s+/, '-')
      if @_assignment
        @_assignment.experiment_salt = salt
      end
    end

    def assign(assignment, args)
      #Returns evaluated PlanOut mapper with experiment assignment
    end

    def __asBlob(extras={})
      #Dictionary representation of experiment data
      requires_assignment
      d = {
        'name': name,
        'time': Time.now.to_i,
        'salt': salt,
        'inputs': @inputs,
        'params': @_assignment.to_h,
      }
      extras.each do |k|
        d[k] = extras[k]
      end
      if @_checksum
        d['checksum'] = @_checksum
      end
      return d
    end

    def checksum
      # if we're running from a file and want to detect if the experiment
      # file has changed
      #if hasattr(main, '__file__') #wtf?????
        # src doesn't count first line of code, which includes function
        # name
        #src = ''.join(inspect.getsourcelines(self.assign)[0][1:])
        #if not isinstance(src, six.binary_type)
        #  src = src.encode("ascii")
        #end
        #return hashlib.sha1(src).hexdigest()[:8]
      # if we're running in an interpreter, don't worry about it
      #else
        #return nil
      #end
    end

    # we should probably get rid of this public interface
    def exposure_logged
      return @_exposure_logged
    end

    def set_auto_exposure_logging(value)
      #Disables / enables auto exposure logging (enabled by default).
      @_auto_exposure_log = value
    end

    def get_params
      #Get all PlanOut parameters. Triggers exposure log.
      # In general, this should only be used by custom loggers.
      requires_assignment
      requires_exposure_logging
      return @_assignment.to_h
    end

    def get(name, default=nil)
      #Get PlanOut parameter (returns default if undefined). Triggers exposure log.
      requires_assignment
      should_log_exposure = true
      if defined? get_param_names
        params = get_param_names
        begin
          name = name.to_sym
        rescue
        end
        should_log_exposure = params.include? name
      end
      requires_exposure_logging(should_log_exposure)
      return @_assignment.get(name, default)
    end

    def to_s
      #String representation of exposure log data. Triggers exposure log.
      requires_assignment
      requires_exposure_logging
      return __asBlob().to_s
    end

    def log_exposure(extras=nil)
      #Logs exposure to treatment
      if !@_in_experiment
        return
      end
      @_exposure_logged = true
      log_event('exposure', extras)
    end

    def log_event(event_type, extras=nil)
      #Log an arbitrary event
      if !@_in_experiment
        return
      end
      if extras
        extra_payload = {'event': event_type, 'extra_data': extras.copy()}
      else
        extra_payload = {'event': event_type}
      end
      log(__asBlob(extra_payload))
    end

    def configure_logger
      #Set up files, database connections, sockets, etc for logging.
    end

    def log(data)
      #Log experimental data
    end

    def previously_logged
      # Check if the input has already been logged.
      # Gets called once during in the constructor.
      # For high-use applications, one might have this method to check if
      # there is a memcache key associated with the checksum of the
      # inputs+params

    end

    # decorator for methods that assume assignments have been made
    def requires_assignment
      _assign if !@_assigned
    end

    # decorator for methods that should be exposure logged
    def requires_exposure_logging(override = true)
      log_exposure if @_auto_exposure_log && @_in_experiment && !@_exposure_logged && override
    end

  end

  class DefaultExperiment < Experiment
    #Dummy experiment which has no logging. Default experiments used by namespaces
    #should inherent from this class.

    def configure_logger
        # we don't log anything when there is no experiment
    end

    def log(data)

    end

    def previously_logged
      return true
    end

    def assign(params, args)
      # more complex default experiments can override this method
      params.update(get_default_params())
    end

    def get_default_params
      #Default experiments that are just key-value stores should
      #override this method.
      return {}
    end

  end


  class SimpleExperiment < Experiment

    #Simple experiment base class which exposure logs to a file

    # We only want to set up the logger once, the first time the object is
    # instantiated. We do this by maintaining this class variable.
    logger = {}
    log_file = {}

    def configure_logger
      # Sets up logger to log to a file
      #my_logger = self.class.logger
      # only want to set logging handler once for each experiment (name)
      #if !self.class.logger.include? name
      #  if !self.class.log_file.include? name
      #    self.class.log_file[name] = "#{name}.log"
      #  end
      #  file_name = self.class.log_file[name]
      #  my_logger[name] = logging.getLogger(name)
      #  my_logger[name].setLevel(logging.INFO)
      #  my_logger[name].addHandler(logging.FileHandler(file_name))
      #  my_logger[name].propagate = false
      #end
    end

    def log(data)
      # Logs data to a file
      #self.class.logger[name].info(JSON.dump(data))
    end

    def set_log_file(path)
      self.class.log_file[name] = path
    end

    def previously_logged
      # Check if the input has already been logged.
      # Gets called once during in the constructor.
      # SimpleExperiment doesn't connect with any services, so we just assume
      # that if the object is a new instance, this is the first time we are
      # seeing the inputs/outputs given.
      return false
    end

  end


  class SimpleInterpretedExperiment < SimpleExperiment
    # A variant of SimpleExperiment that loads data from a given script

    def loadScript
      # loads deserialized PlanOut script to be executed by the interpreter
      # This method should set self.script to a dictionary-based representation
      # of a PlanOut script. Most commonly, this method would retreive a
      # JSON-encoded string from a database or file, e.g.
      # self.script = JSON.loads(open("myfile").read())
      # If constructing experiments on the fly, one can alternatively set the
      # self.script instance variable

    end

    def assign(params, args)
      loadScript()  # lazily load script
      # script must be a dictionary
      #assert script.present? && type(script) == dict

      interpreterInstance = Interpreter.new(
        @script,
        salt,
        args,
        params
      )
      # execute script
      results = interpreterInstance.get_params()
      # insert results into param object dictionary
      params.update(results)
      return interpreterInstance.in_experiment
    end

    def checksum
      # script must be a dictionary
      #assert script.present? && type(script) == dict
      src = JSON.dump(@script)

      #if not isinstance(src, six.binary_type)
      #  src = src.encode("ascii")
      #end
      #return hashlib.sha1(src).hexdigest()[:8]
    end
  end

  class ProductionExperiment < Experiment
    # A variant of SimpleExperiment that verifies that exposure is only logged
    # when a valid parameter is fetched via the get method

    #Returns a list of assignment parameter values that this experiment can take
    #@abstractmethod
    def get_param_names
    end

  end

end
