class VpcsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vpc, only: [:show]
  layout 'frontend'

  # GET /vpcs
  # GET /vpcs.json
  def index
    @vpcs = Vpc.order(:name).all
  end

  # GET /vpcs/1
  # GET /vpcs/1.json
  def show

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vpc
      @vpc = Vpc.find(params[:id])
      params[:start_date]=@vpc.reports.json_ready.order(updated_at: :desc).limit(1).first.start_date.to_s unless params[:start_date]
      start_date=Date.parse(params[:start_date]).at_beginning_of_month

      global_report_ids=GlobalReport.where(start_date: start_date..start_date.next_month).ids
      @reports=@vpc.reports.json_ready.where(global_report_id: global_report_ids ).all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vpc_params
      params.fetch(:vpc, {})
    end
end
