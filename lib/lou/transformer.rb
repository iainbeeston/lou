module Lou
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
