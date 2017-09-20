require 'test_helper'

class HistoryTest < ActiveSupport::TestCase
  test "verbose" do
    History.verbose = true
    out = util_capture do
      History.write("Hello")
    end
    assert_equal "Hello\n", out
  end

  test "non verbose" do
    History.verbose = false
    out = util_capture do
      History.write("Hello")
    end
    assert_equal "", out
  end
end
