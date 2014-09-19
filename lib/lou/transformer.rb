require 'lou/transformer/step'

module Lou
  module Transformer
    # never raise this...
    class NeverError < StandardError; end

    attr_accessor :steps, :error_class

    def self.extended(base)
      base.class_eval do
        self.steps = []
        self.error_class = Lou::Transformer::NeverError
      end
    end

    def reverse_on(error)
      self.error_class = error
    end

    def step(transformer)
      transformer.tap do |t|
        self.steps += [t]
      end
    end

    def up(&block)
      Transformer::Step.new.up(&block)
    end

    def down(&block)
      Transformer::Step.new.down(&block)
    end

    def apply(input, total_steps = steps.count)
      applied_steps = 0
      begin
        steps.last(total_steps).each do |t|
          input = t.apply(input)
          applied_steps += 1
        end
      rescue error_class => e
        reverse(input, applied_steps) if total_steps == steps.count
        raise e
      end
      input
    end

    def reverse(output, total_steps = steps.count)
      reversed_steps = 0
      begin
        steps.first(total_steps).reverse_each do |t|
          output = t.reverse(output)
          reversed_steps += 1
        end
      rescue error_class => e
        apply(output, reversed_steps) if total_steps == steps.count
        raise e
      end
      output
    end
  end
end
