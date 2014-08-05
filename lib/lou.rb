require 'lou/version'

module Lou
  def self.extended(base)
    base.class_eval do
      @forward_transforms = []
      @backward_transforms = []
    end
  end

  def transform(mapping)
    @forward_transforms << mapping.fwd
    @backward_transforms << mapping.bwd
    self
  end

  def apply(input)
    output = deep_clone(input)
    @forward_transforms.each do |t|
      output = t.call(output)
    end
    output
  end

  def undo(output)
    input = deep_clone(output)
    @backward_transforms.reverse_each do |t|
      input = t.call(input)
    end
    input
  end

  def deep_clone(obj)
    Marshal.load(Marshal.dump(obj))
  end

  def forward(&block)
    Transformer.new(&block)
  end

  class Transformer
    def initialize(&block)
      forward(&block)
    end

    def forward(&block)
      @forward = block
      self
    end

    def backward(&block)
      @backward = block
      self
    end

    def fwd
      @forward
    end

    def bwd
      @backward
    end
  end
end
