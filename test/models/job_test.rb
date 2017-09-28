require 'test_helper'

class JobTest < ActiveSupport::TestCase
  test "#run!" do
    job=jobs(:one)
    job.run!
    job.reload
    assert_equal job.out, 'Hello'
  end
end
