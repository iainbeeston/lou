require 'lou'
require 'spec_helper'

describe Lou do
  context 'with no transformations defined' do
    let(:klass) do
      Class.new do
        extend Lou
      end
    end

    describe '#apply' do
      it 'returns the input' do
        expect(klass.apply('this is the input')).to eq('this is the input')
      end
    end

    describe '#undo' do
      it 'returns the input' do
        expect(klass.undo('this is the input')).to eq('this is the input')
      end
    end
  end

  context 'with one transform' do
    let(:klass) do
      Class.new do
        extend Lou
        transform forward { |x| x.push 'world' }.backward { |x| x.delete_if { |y| y == 'world' } }
      end
    end

    describe '#apply' do
      it 'applies the forward transform' do
        expect(klass.apply(%w(hello))).to eq(%w(hello world))
      end

      it 'does not change the input object' do
        input = %w(hello)
        expect { klass.apply(input) }.to_not change { input }
      end
    end

    describe '#undo' do
      it 'applies the backward transform' do
        expect(klass.undo(%w(hello world))).to eq(%w(hello))
      end

      it 'does not change the input object' do
        input = %w(hello world)
        expect { klass.undo(input) }.to_not change { input }
      end
    end
  end

  context 'with two transforms' do
    let(:klass) do
      Class.new do
        extend Lou
        transform forward { |x| x + ', or not to be' }.backward { |x| x.gsub(/, or not to be$/, '') }
        transform forward { |x| x + ', that is the question.' }.backward { |x| x.gsub(/, that is the question\.$/, '') }
      end
    end

    describe '#apply' do
      it 'applies all of the forward transforms in order' do
        expect(klass.apply('To be')).to eq('To be, or not to be, that is the question.')
      end
    end

    describe '#undo' do
      it 'applies all of the backward transforms in reverse order' do
        expect(klass.undo('To be, or not to be, that is the question.')).to eq('To be')
      end
    end
  end
end
