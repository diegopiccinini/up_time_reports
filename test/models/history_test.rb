require 'test_helper'

class HistoryTest < ActiveSupport::TestCase

  test "verbose" do
    History.verbose = true

    out = util_capture do
      History.start 'TestJob'
      History.write "Hello"
      History.finish
    end

    assert out.include?"Hello\n"
  end

  test "verbose with return lines" do
    History.verbose = true

    out = util_capture do
      History.start 'TestJob'
      History.write "Hello", 2, 2
      History.finish
    end

    assert out.include?"\n\nHello\n\n"
  end

  test "non verbose" do
    History.verbose = false

    out = util_capture do
      History.start 'TestJob'
      History.write "Hello"
      History.finish
    end

    assert_not out.include?"Hello"
  end
end
