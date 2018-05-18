# frozen-string-literal: true

# An extension of a standard hash that auto-adds keys that are requested
# but are not present
class AutoExtendHash < Hash
  def initialize
    super(&method(:auto_extending_hash))
  end

  def self.auto_extend(hash)
    hash.default_proc = ->(hsh, key) { hsh[key] = AutoExtendHash.new }
  end

  def auto_extending_hash(hash, key)
    hash[key] = AutoExtendHash.new
  end
end
