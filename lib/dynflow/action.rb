module Dynflow
  class Action < Message

    def self.inherited(child)
      self.actions << child
    end

    def self.actions
      @actions ||= []
    end

    def self.subscribe
      nil
    end

    def self.require
      nil
    end

    def initialize(input, output = {})
      # for preparation phase
      @execution_plan = []

      output ||= {}
      super('input' => input, 'output' => output)
    end

    def input
      @data['input']
    end

    def input=(input)
      @data['input'] = input
    end

    def output
      @data['output']
    end

    # the block contains the expression in Apipie::Params::DSL
    # describing the format of message
    def self.input_format(&block)
      if block
        @input_format_block = block
      elsif @input_format_block
        @input_format ||= Apipie::Params::Description.define(&@input_format_block)
      else
        nil
      end
    end

    # the block contains the expression in Apipie::Params::DSL
    # describing the format of message
    def self.output_format(&block)
      if block
        @output_format_block = block
      elsif @output_format_block
        @output_format ||= Apipie::Params::Description.define(&@output_format_block)
      else
        nil
      end
    end

    def self.trigger(*args)
      Dynflow::Bus.trigger(self.plan(*args))
    end

    def self.plan(*args)
      action = self.new({})
      yield action if block_given?
      action.plan(*args)
      action.add_subscriptions(*args)
      action.execution_plan
    end

    # for subscribed actions: by default take the input of the
    # subscribed action
    def plan(*args)
      plan_self(self.input)
    end

    def plan_self(input)
      self.input = input
      @execution_plan << [self.class, input]
    end

    def plan_action(action_class, *args)
      sub_action_plan = action_class.plan(*args) do |action|
        action.input = args.first
      end
      @execution_plan.concat(sub_action_plan)
    end

    def add_subscriptions(*plan_args)
      @execution_plan.concat(Dispatcher.execution_plan_for(self, *plan_args))
    end

    def execution_plan
      @execution_plan
    end

    def validate!
      self.clss.output_format.validate!(@data['output'])
    end

  end
end