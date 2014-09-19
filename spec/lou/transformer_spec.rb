require 'lou/transformer'
require 'spec_helper'

module Lou
  describe Transformer do
    context 'with no steps defined' do
      let!(:klass) do
        Class.new do
          extend Lou::Transformer
        end
      end

      describe '#apply' do
        it 'returns the input' do
          expect(klass.apply('this is the input')).to eq('this is the input')
        end
      end

      describe '#revert' do
        it 'returns the input' do
          expect(klass.revert('this is the input')).to eq('this is the input')
        end
      end
    end

    context 'with one step' do
      let!(:klass) do
        Class.new do
          extend Lou::Transformer
          step up { |x| x.push 'world' }.down { |x| x.delete_if { |y| y == 'world' } }
        end
      end

      describe '#apply' do
        it 'applies the up step' do
          expect(klass.apply(%w(hello))).to eq(%w(hello world))
        end
      end

      describe '#revert' do
        it 'applies the down step' do
          expect(klass.revert(%w(hello world))).to eq(%w(hello))
        end
      end
    end

    context 'with two steps' do
      let!(:klass) do
        Class.new do
          extend Lou::Transformer
          step up { |x| x + ', or not to be' }.down { |x| x.gsub(/, or not to be$/, '') }
          step up { |x| x + ', that is the question.' }.down { |x| x.gsub(/, that is the question\.$/, '') }
        end
      end

      describe '#apply' do
        it 'applies all of the up steps in order' do
          expect(klass.apply('To be')).to eq('To be, or not to be, that is the question.')
        end
      end

      describe '#revert' do
        it 'applies all of the down steps in revert order' do
          expect(klass.revert('To be, or not to be, that is the question.')).to eq('To be')
        end
      end
    end

    context 'when one of the steps is another transformer' do
      let!(:grandchild) do
        parent = Class.new do
          extend Lou::Transformer
          step up { |x| x.create; x }.down { |x| x.destroy; x }
        end

        child = Class.new do
          extend Lou::Transformer

          step(parent)

          step up { |x| x.create; x }.down { |x| x.destroy; x }
        end

        Class.new do
          extend Lou::Transformer

          step(child)

          step up { |x| x.create; x }.down { |x| x.destroy; x }
        end
      end

      let(:target) { instance_double('Target') }

      describe '#apply' do
        it 'applies the steps of the parent first, then the child' do
          expect(target).to receive(:create).exactly(3).times
          grandchild.apply(target)
        end
      end

      describe '#revert' do
        it 'reverts the steps of the child first, then the parent' do
          expect(target).to receive(:destroy).exactly(3).times
          grandchild.revert(target)
        end
      end
    end

    context 'when an error is raised' do
      let!(:klass) do
        Class.new do
          extend Lou::Transformer
          step up { |_| fail 'error on up' }.down { |_| fail 'error on down' }
        end
      end

      describe '#apply' do
        it 'raises the exception' do
          expect { klass.apply('foo') }.to raise_error('error on up')
        end
      end

      describe '#revert' do
        it 'raises the exception' do
          expect { klass.revert('bar') }.to raise_error('error on down')
        end
      end
    end

    context 'when #revert_on has been set' do
      let!(:error_class) do
        class SpecialError < StandardError; end
      end

      let(:target) { instance_double('Target') }

      context 'and an error is raised on the first step' do
        let!(:klass) do
          Class.new do
            extend Lou::Transformer
            revert_on(SpecialError)

            step up { |_| fail SpecialError }.down { |x| x.destroy(1); x  }
            step up { |x| x.create(2); x }.down { |_| fail SpecialError }
          end
        end

        describe '#apply' do
          it 'reverts no steps when the specified error is raised' do
            expect(target).to_not receive(:create)
            expect(target).to_not receive(:destroy)
            expect { klass.apply(target) }.to raise_error(SpecialError)
          end
        end

        describe '#revert' do
          it 'applies no steps when the specified error is raised' do
            expect(target).to_not receive(:destroy)
            expect(target).to_not receive(:create)
            expect { klass.revert(target) }.to raise_error(SpecialError)
          end
        end
      end

      context 'and an error is raised part-way through the transform' do
        let!(:klass) do
          Class.new do
            extend Lou::Transformer
            revert_on(SpecialError)

            step up { |x| x.create(1); x }.down { |x| x.destroy(1); x }
            step up { |_| fail SpecialError }.down { |_| fail SpecialError }
            step up { |x| x.create(3); x }.down { |x| x.destroy(3); x }
          end
        end

        describe '#apply' do
          it 'reverts all successfully applied steps before raising the error when the specified error is raised' do
            expect(target).to receive(:create).once.with(1).ordered
            expect(target).to receive(:destroy).once.with(1).ordered
            expect { klass.apply(target) }.to raise_error(SpecialError)
          end
        end

        describe '#revert' do
          it 'reapplies all successfully revertd steps before raising the error when the specified error is raised' do
            expect(target).to receive(:destroy).once.with(3).ordered
            expect(target).to receive(:create).once.with(3).ordered
            expect { klass.revert(target) }.to raise_error(SpecialError)
          end
        end
      end

      context 'and the up and down steps should lead to an infinite loop' do
        let!(:klass) do
          Class.new do
            extend Lou::Transformer
            revert_on(SpecialError)

            step up { |x| x.create(1); x }.down { |_| fail SpecialError, 'fail on down' }
            step up { |_| fail SpecialError, 'fail on up' }.down { |x| x.destroy(2); x }
          end
        end

        describe '#apply' do
          it 'raises the error from the down step' do
            expect(target).to receive(:create).once.with(1)
            expect { klass.apply(target) }.to raise_error(SpecialError, 'fail on down')
          end
        end

        describe '#revert' do
          it 'raises the error from the up step' do
            expect(target).to receive(:destroy).once.with(2)
            expect { klass.revert(target) }.to raise_error(SpecialError, 'fail on up')
          end
        end
      end
    end
  end
end
