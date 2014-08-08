require 'lou/transformer'
require 'spec_helper'

module Lou
  describe Transformer do
    context 'with no steps defined' do
      let(:klass) do
        Class.new do
          extend Lou::Transformer
        end
      end

      describe '#apply' do
        it 'returns the input' do
          expect(klass.apply('this is the input')).to eq('this is the input')
        end
      end

      describe '#reverse' do
        it 'returns the input' do
          expect(klass.reverse('this is the input')).to eq('this is the input')
        end
      end
    end

    context 'with one step' do
      let(:klass) do
        Class.new do
          extend Lou::Transformer
          step.up { |x| x.push 'world' }.down { |x| x.delete_if { |y| y == 'world' } }
        end
      end

      describe '#apply' do
        it 'applies the up step' do
          expect(klass.apply(%w(hello))).to eq(%w(hello world))
        end

        it 'does not change the input object' do
          input = %w(hello)
          expect { klass.apply(input) }.to_not change { input }
        end
      end

      describe '#reverse' do
        it 'applies the down step' do
          expect(klass.reverse(%w(hello world))).to eq(%w(hello))
        end

        it 'does not change the input object' do
          input = %w(hello world)
          expect { klass.reverse(input) }.to_not change { input }
        end
      end
    end

    context 'with two steps' do
      let(:klass) do
        Class.new do
          extend Lou::Transformer
          step.up { |x| x + ', or not to be' }.down { |x| x.gsub(/, or not to be$/, '') }
          step.up { |x| x + ', that is the question.' }.down { |x| x.gsub(/, that is the question\.$/, '') }
        end
      end

      describe '#apply' do
        it 'applies all of the up steps in order' do
          expect(klass.apply('To be')).to eq('To be, or not to be, that is the question.')
        end
      end

      describe '#reverse' do
        it 'applies all of the down steps in reverse order' do
          expect(klass.reverse('To be, or not to be, that is the question.')).to eq('To be')
        end
      end
    end
  end
end
