Bundler.setup :default, :test

require "hugs"

require "minitest/spec"
require "webmock"

class MiniTest::Unit::TestCase
  include WebMock::API
end

MiniTest::Unit.autorun
