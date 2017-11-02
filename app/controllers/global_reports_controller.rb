class GlobalReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_global_report, only: [:show]
  layout 'frontend'

  # GET /global_reports
  # GET /global_reports.json
  def index
    params[:start_date]=GlobalReport.json_ready.order(start_date: :desc).limit(1).first.start_date.to_s unless params[:start_date]
    start_date=Date.parse(params[:start_date]).at_beginning_of_month
    @global_reports=GlobalReport.json_ready.where(start_date: start_date..start_date.next_month).all
  end

  # GET /global_reports/1
  # GET /global_reports/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_global_report
      @global_report = GlobalReport.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def global_report_params
      params.fetch(:global_report, {})
    end
end
