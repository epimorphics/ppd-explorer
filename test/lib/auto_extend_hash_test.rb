# frozen-string-literal: true

require 'test_helper'

# Unit tests on auto-extending hash. This supports easy creation of highly
# nested structures, such as JSON trees. Each time a key is accessed that is
# not present, it will automatically instantiate the key value with an
# extending hash.
class AutoExtendHashTest < ActiveSupport::TestCase
  describe 'AutoExtendHash' do
    describe 'creating a new hash' do
      it 'should create a hash that auto-extends' do
        auto_hash = AutoExtendHash.new

        refute auto_hash.key?(:foo)
        auto_hash[:foo].wont_be_nil
        assert auto_hash.key?(:foo)
      end
    end

    describe 'accessing the hash' do
      it 'should allow assignment to a new key like a normal hash' do
        auto_hash = AutoExtendHash.new

        refute auto_hash.key?(:foo)
        auto_hash[:foo] = :bar
        assert auto_hash.key?(:foo)
        auto_hash[:foo].must_equal :bar
      end

      it 'should support nested accesses' do
        auto_hash = AutoExtendHash.new

        auto_hash[:foo][:fubar][:rabuf] = :bar
        auto_hash[:foo][:fubar][:rabuf].must_equal :bar
      end
    end

    describe 'converting an existing hash' do
      it 'should allow an existing hash to be converted to auto-extend behaviour' do
        orig = {}

        refute orig.key?(:foo)
        orig[:foo]
        refute orig.key?(:foo)

        AutoExtendHash.auto_extend(orig)
        refute orig.key?(:foo)
        orig[:foo]
        assert orig.key?(:foo)
      end

      it 'should support nested access in converted hashes' do
        orig = {}
        AutoExtendHash.auto_extend(orig)

        refute orig.key?(:foo)
        orig[:foo][:bar] = 'wombles'
        orig[:foo][:bar].must_equal 'wombles'
      end
    end
  end
end
