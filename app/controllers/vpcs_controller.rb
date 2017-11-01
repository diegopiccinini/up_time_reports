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
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vpc_params
      params.fetch(:vpc, {})
    end
end
