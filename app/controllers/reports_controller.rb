class ReportsController < ApplicationController
  before_action :authenticate_user!
  layout 'frontend'
  def show
    @report= Report.find(params[:id])
  end
end
