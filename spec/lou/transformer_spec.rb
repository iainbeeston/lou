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
      end

      describe '#reverse' do
        it 'applies the down step' do
          expect(klass.reverse(%w(hello world))).to eq(%w(hello))
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

    context 'when extended from another transformer' do
      let(:parent) do
        Class.new do
          extend Lou::Transformer
          step.up { |x| x.create; x }.down { |x| x.destroy; x }
        end
      end
      let(:child) do
        Class.new(parent) do
          step.up { |x| x.create; x }.down { |x| x.destroy; x }
        end
      end
      let(:grandchild) do
        Class.new(child) do
          step.up { |x| x.create; x }.down { |x| x.destroy; x }
        end
      end

      let(:target) { instance_double('Target') }

      describe '#apply' do
        it 'applies the steps of the parent first, then the child' do
          expect(target).to receive(:create).exactly(3).times
          grandchild.apply(target)
        end

        it 'does not alter the up steps of the parent' do
          expect(target).to receive(:create).exactly(1).times
          parent.apply(target)
        end
      end

      describe '#reverse' do
        it 'reverses the steps of the child first, then the parent' do
          expect(target).to receive(:destroy).exactly(3).times
          grandchild.reverse(target)
        end

        it 'does not alter the down steps of the parent' do
          expect(target).to receive(:destroy).exactly(1).times
          parent.reverse(target)
        end
      end
    end

    context 'when an error is raised' do
      let(:klass) do
        Class.new do
          extend Lou::Transformer
          step.up { |_| fail 'error on up' }.down { |_| fail 'error on down' }
        end
      end

      describe '#apply' do
        it 'raises the exception' do
          expect { klass.apply('foo') }.to raise_error('error on up')
        end
      end

      describe '#reverse' do
        it 'raises the exception' do
          expect { klass.reverse('bar') }.to raise_error('error on down')
        end
      end
    end

    context 'when #reverse_on has been set' do
      let(:parent) do
        Class.new do
          extend Lou::Transformer

          class SpecialError < StandardError; end

          reverse_on SpecialError
        end
      end

      let(:target) { instance_double('Target') }

      context 'and an error is raised on the first step' do
        let(:klass) do
          Class.new(parent) do
            step.up { |_| fail SpecialError }.down { |x| x.destroy(1); x  }
            step.up { |x| x.create(2); x }.down { |_| fail SpecialError }
          end
        end

        describe '#apply' do
          it 'reverses no steps when the specified error is raised' do
            expect(target).to_not receive(:create)
            expect(target).to_not receive(:destroy)
            klass.apply(target)
          end
        end

        describe '#reverse' do
          it 'applies no steps when the specified error is raised' do
            expect(target).to_not receive(:destroy)
            expect(target).to_not receive(:create)
            klass.reverse(target)
          end
        end
      end

      context 'and an error is raised part-way through the transform' do
        let(:klass) do
          Class.new(parent) do
            step.up { |x| x.create(1); x }.down { |x| x.destroy(1); x }
            step.up { |_| fail SpecialError }.down { |_| fail SpecialError }
            step.up { |x| x.create(3); x }.down { |x| x.destroy(3); x }
          end
        end

        let(:target) { instance_double('Target') }

        describe '#apply' do
          it 'reverses all successfully applied steps when the specified error is raised' do
            expect(target).to receive(:create).once.with(1).ordered
            expect(target).to receive(:destroy).once.with(1).ordered
            klass.apply(target)
          end
        end

        describe '#reverse' do
          it 'reapplies all successfully reversed steps when the specified error is raised' do
            expect(target).to receive(:destroy).once.with(3).ordered
            expect(target).to receive(:create).once.with(3).ordered
            klass.reverse(target)
          end
        end
      end

      context 'and the up and down steps should lead to an infinite loop' do
        let(:klass) do
          Class.new(parent) do
            step.up { |x| x.create(1); x }.down { |_| fail SpecialError, 'fail on down' }
            step.up { |_| fail SpecialError, 'fail on up' }.down { |x| x.destroy(2); x }
          end
        end

        describe '#apply' do
          it 'raises the error from the down step' do
            expect(target).to receive(:create).once.with(1)
            expect { klass.apply(target) }.to raise_error(SpecialError, 'fail on down')
          end
        end

        describe '#reverse' do
          it 'raises the error from the up step' do
            expect(target).to receive(:destroy).once.with(2)
            expect { klass.reverse(target) }.to raise_error(SpecialError, 'fail on up')
          end
        end
      end
    end
  end
end
