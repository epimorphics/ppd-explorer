# frozen_string_literal: true

module Version
  MAJOR = 2
  MINOR = 8
  PATCH = 0
  SUFFIX = nil
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && ".#{SUFFIX}"}"
end
