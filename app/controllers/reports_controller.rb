class ReportsController < ApplicationController
  layout 'frontend'
  def show
    @report= Report.find(params[:id])
  end
end
