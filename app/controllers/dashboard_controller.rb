class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout 'frontend'


  def index
    @weekly_global_reports=GlobalReport.built.where(period: 'week').order(start_date: :desc).limit(10).all
    @daily_global_reports=GlobalReport.built.where(period: 'day').order(start_date: :desc).limit(10).all
    @monthly_global_reports=GlobalReport.built.where(period: 'month', resolution: 'day').order(start_date: :desc).limit(10).all
    @yearly_global_reports=GlobalReport.built.where(period: 'year').order(updated_at: :desc).limit(10).all

    @latest_global_daily=GlobalReport.where(period: 'day').built.order(start_date: :desc).limit(1).first
    @daily_reports=[]
    @daily_reports=@latest_global_daily.reports.where(status: 'JSON ready').includes(:vpc).order('vpcs.name') if @latest_global_daily

    @latest_global_weekly=GlobalReport.where(period: 'week').built.order(start_date: :desc).limit(1).first
    @weekly_reports=[]
    @weekly_reports=@latest_global_weekly.reports.includes(:vpc).where(status: 'JSON ready').order('vpcs.name') if @latest_global_weekly
  end
end
