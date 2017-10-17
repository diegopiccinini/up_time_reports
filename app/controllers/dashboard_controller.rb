class DashboardController < ApplicationController
  layout 'frontend'
  def index
    @global_reports=GlobalReport.built.order(updated_at: :desc).all
    @latest_global_daily=GlobalReport.where(period: 'day').built.last
    @daily_reports=@latest_global_daily.reports.includes(:vpc).order('vpcs.name')
    @latest_global_weekly=GlobalReport.where(period: 'week').built.last
    @weekly_reports=@latest_global_weekly.reports.includes(:vpc).order('vpcs.name')
  end
end
