require 'test_helper'

class GlobalSettingTest < ActiveSupport::TestCase

  test "#set and get" do

    data_hash = { id: 1, name: 'Name 1' }
    assert GlobalSetting.set( 'test_var', data_hash)

    get_hash = GlobalSetting.get 'test_var'
    assert_equal get_hash, data_hash
  end
end
