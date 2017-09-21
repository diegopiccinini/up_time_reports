require 'test_helper'

class HistoryTest < ActiveSupport::TestCase
  test "verbose" do
    History.verbose = true
    out = util_capture do
      History.write "Hello"
    end
    assert_equal "Hello\n", out
  end

  test "verbose with return lines" do
    History.verbose = true
    out = util_capture do
      History.write "Hello", 2, 2
    end
    assert_equal "\n\nHello\n\n", out
  end

  test "non verbose" do
    History.verbose = false
    out = util_capture do
      History.write "Hello"
    end
    assert_equal "", out
  end
end
