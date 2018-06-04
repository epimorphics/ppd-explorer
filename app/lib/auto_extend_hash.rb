# frozen-string-literal: true

# An extension of a standard hash that auto-adds keys that are requested
# but are not present
class AutoExtendHash < Hash
  def initialize
    super(&method(:auto_extending_hash))
  end

  # Make the given hash auto-extending, but don't replace existing default_proc
  # behaviour. Will also traverse the values of the hash, recursively, to convert
  # nested values to auto-extend as well.
  def self.auto_extend(hash)
    return unless hash.is_a?(Hash)
    conditionally_set_default_proc(hash)
    hash.values.each { |value| AutoExtendHash.auto_extend(value) }
  end

  def auto_extending_hash(hash, key)
    hash[key] = AutoExtendHash.new
  end

  def self.conditionally_set_default_proc(hash)
    return if hash.default_proc
    hash.default_proc = ->(hsh, key) { hsh[key] = AutoExtendHash.new }
  end
end
