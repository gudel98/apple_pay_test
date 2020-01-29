class BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[capture void refund]

  def index
  end

  def capture
    sleep 0.5
    status = 200
    currency = 'USD'
    message = "#{params[:parent_uid]}: #{params[:amount]} #{currency} was successfully captured"
    render json: { status: status, message: message }
  end

  def void
    sleep 0.5
    status = 200
    currency = 'USD'
    message = "#{params[:parent_uid]}: #{params[:amount]} #{currency} was successfully voided"
    render json: { status: status, message: message }
  end

  def refund
    sleep 0.5
    status = 200
    currency = 'USD'
    message = "#{params[:parent_uid]}: #{params[:amount]} #{currency} was successfully refunded"
    render json: { status: status, message: message }
  end

  private

  def money_format(amount)
    # Money.new()
  end
end
