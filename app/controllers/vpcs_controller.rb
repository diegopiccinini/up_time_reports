class VpcsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vpc, only: [:show]

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
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def vpc_params
      params.fetch(:vpc, {})
    end
end
