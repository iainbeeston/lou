require 'lou/version'

module Lou
  def self.extended(base)
    base.class_eval do
      @transforms = []
    end
  end

  def transform(mapping)
    @transforms << mapping
    self
  end

  def apply(input)
    output = deep_clone(input)
    @transforms.each do |t|
      output = t.apply(output)
    end
    output
  end

  def undo(output)
    input = deep_clone(output)
    @transforms.reverse_each do |t|
      input = t.undo(input)
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

    def apply(input)
      @forward.nil? ? input : @forward.call(input)
    end

    def undo(output)
      @backward.nil? ? output : @backward.call(output)
    end
  end
end
