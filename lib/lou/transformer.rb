module Lou
  class Transformer
    def up(&block)
      @up = block
      self
    end

    def down(&block)
      @down = block
      self
    end

    def apply(input)
      @up.nil? ? input : @up.call(input)
    end

    def reverse(output)
      @down.nil? ? output : @down.call(output)
    end
  end
end
