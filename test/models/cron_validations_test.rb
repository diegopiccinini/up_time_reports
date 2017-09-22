require 'test_helper'

class CronValidationsTest < ActiveSupport::TestCase

  setup do
    @cron = Cron.new
  end

  test "should has a job" do

    assert_not @cron.valid?
    assert @cron.errors.keys.include?(:job)

    @cron.job= jobs(:one)
    @cron.valid?
    assert_not @cron.errors.keys.include?(:job)

  end

  test "should has a name" do
    assert_not @cron.valid?
    assert @cron.errors.keys.include?(:name)

    @cron.name= 'Cron test'
    @cron.valid?
    assert_not @cron.errors.keys.include?(:name)
  end


  test "should validate precense_of status, hour" do

    assert_not @cron.valid?
    assert_not @cron.errors.keys.include?(:status)
    assert @cron.errors.keys.include?(:hour)
    @cron.status= 'bad status'
    @cron.valid?
    assert @cron.errors.keys.include?(:status)

    %w(ok running error).each do |status|
      @cron.status = status
      @cron.valid?
      assert_not @cron.errors.keys.include?(:status)
    end

    23.times do |h|
      @cron.hour = h
      @cron.valid?
      assert_not @cron.errors.keys.include?(:hour)
    end
  end

  test "should has a valid month" do

    @cron.valid?
    assert_not @cron.errors.keys.include?(:month)

    1.upto(12) do |m|
      @cron.month=m
      @cron.valid?
      assert_not @cron.errors.keys.include?(:month)
    end

    [-1,0,13].each do |m|
      @cron.month=m
      @cron.valid?
      assert @cron.errors.keys.include?(:month)
    end

  end

  test "should has a valid day_of_week" do

    @cron.valid?
    assert_not @cron.errors.keys.include?(:day_of_week)

    7.times do |d|
      @cron.day_of_week = d
      @cron.valid?
      assert_not @cron.errors.keys.include?(:day_of_week)
    end

    [-1, 7].each do |d|
      @cron.day_of_week = d
      @cron.valid?
      assert @cron.errors.keys.include?(:day_of_week)
    end

  end

  test "should has a valid day_of_month" do

    @cron.valid?
    assert_not @cron.errors.keys.include?(:day_of_month)

    1.upto(31) do |d|
      @cron.day_of_month = d
      @cron.valid?
      assert_not @cron.errors.keys.include?(:day_of_month)
    end

    [-1,0, 32].each do |d|
      @cron.day_of_month = d
      @cron.valid?
      assert @cron.errors.keys.include?(:day_of_month)
    end

  end

  test "invalid month and day of month" do
    @cron.month=2
    @cron.day_of_month=30
    @cron.valid?
    assert @cron.errors.keys.include?(:day_of_month)
  end

  test "should be valid" do
    cron = Cron.new
    cron.job = jobs(:one)
    cron.name='Test cron'
    cron.hour = 8
    assert cron.valid?
  end

end
