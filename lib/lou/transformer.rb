require 'lou/transformer/step'

module Lou
  module Transformer
    def self.extended(base)
      base.class_eval do
        @steps = []
      end
    end

    def step
      Step.new.tap do |t|
        @steps << t
      end
    end

    def apply(input)
      output = deep_clone(input)
      @steps.each do |t|
        output = t.apply(output)
      end
      output
    end

    def reverse(output)
      input = deep_clone(output)
      @steps.reverse_each do |t|
        input = t.reverse(input)
      end
      input
    end

    def deep_clone(obj)
      Marshal.load(Marshal.dump(obj))
    end
  end
end
