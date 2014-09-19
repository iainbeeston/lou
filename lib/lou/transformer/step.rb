module Lou
  module Transformer
    class Step
      def up(&block)
        self.up_blk = block
        self
      end

      def down(&block)
        self.down_blk = block
        self
      end

      def apply(input)
        up_blk.nil? ? input : up_blk.call(input)
      end

      def revert(output)
        down_blk.nil? ? output : down_blk.call(output)
      end

      protected

      attr_accessor :up_blk, :down_blk
    end
  end
end
