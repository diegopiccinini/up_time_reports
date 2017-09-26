require 'test_helper'

class VpcUpdateJobTest < ActiveJob::TestCase
  test "return history" do
    History.reset
    stub_checks
    assert_kind_of History, VpcUpdateJob.perform_now
  end
end
