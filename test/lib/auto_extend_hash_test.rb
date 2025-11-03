# frozen_string_literal: true

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
        refute_nil auto_hash[:foo]
        assert auto_hash.key?(:foo)
      end
    end

    describe 'accessing the hash' do
      it 'should allow assignment to a new key like a normal hash' do
        auto_hash = AutoExtendHash.new

        refute auto_hash.key?(:foo)
        auto_hash[:foo] = :bar
        assert auto_hash.key?(:foo)
        assert_equal :bar, auto_hash[:foo]
      end

      it 'should support nested accesses' do
        auto_hash = AutoExtendHash.new

        auto_hash[:foo][:fubar][:rabuf] = :bar
        assert_equal :bar, auto_hash[:foo][:fubar][:rabuf]
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
        assert_equal 'wombles', orig[:foo][:bar]
      end

      it 'should convert nested hashes to auto-extend' do
        orig = { foo: {} }
        AutoExtendHash.auto_extend(orig)

        refute orig[:foo].key?(:bar)
        orig[:foo][:bar][:fubar] = 'wombles'
        assert_equal 'wombles', orig[:foo][:bar][:fubar]
      end

      it 'should not change existing default_proc behaviour' do
        orig = Hash.new { |hash, key| hash[key] = :chewbacca }
        AutoExtendHash.auto_extend(orig)

        refute orig.key?(:foo)
        assert_equal :chewbacca, orig[:foo]
      end
    end
  end
end
