require 'active_support/core_ext/class/attribute'
require 'lou/transformer/step'

module Lou
  module Transformer
    def self.extended(base)
      base.class_eval do
        class_attribute(:steps)
        self.steps = []
      end
    end

    def step
      Step.new.tap do |t|
        steps << t
      end
    end

    def apply(input)
      steps.each do |t|
        input = t.apply(input)
      end
      input
    end

    def reverse(output)
      steps.reverse_each do |t|
        output = t.reverse(output)
      end
      output
    end
  end
end
