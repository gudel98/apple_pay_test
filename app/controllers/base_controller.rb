class BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[refund]

  def index
  end

  def refund
    sleep 4
    {status: 200, message: 'Successfully refunded'}
  end
end
