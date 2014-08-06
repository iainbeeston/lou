require 'lou/version'
require 'lou/transformer'

module Lou
  def self.extended(base)
    base.class_eval do
      @transforms = []
    end
  end

  def transform
    Transformer.new.tap do |t|
      @transforms << t
    end
  end

  def apply(input)
    output = deep_clone(input)
    @transforms.each do |t|
      output = t.apply(output)
    end
    output
  end

  def reverse(output)
    input = deep_clone(output)
    @transforms.reverse_each do |t|
      input = t.reverse(input)
    end
    input
  end

  def deep_clone(obj)
    Marshal.load(Marshal.dump(obj))
  end
end
