# frozen_string_literal: true

module Version
  MAJOR = 1
  MINOR = 7
  PATCH = 3
  SUFFIX = 1
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}#{SUFFIX && ".#{SUFFIX}"}"
end
