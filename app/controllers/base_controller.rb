class BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, except: :index

  def index
  end

  def capture
    data = {
      amount: money_format(params[:amount]),
      parent_uid: params[:parent_uid]
    }
    commit('capture', data)
  end

  def void
    data = {
      amount: money_format(params[:amount]),
      parent_uid: params[:parent_uid]
    }
    commit('void', data)
  end

  def refund
    data = {
      amount: money_format(params[:amount]),
      parent_uid: params[:parent_uid],
      reason: 'ApplePay test refund'
    }
    commit('refund', data)
  end

  def recurring
    data = {
      request: {
        amount: money_format(params[:amount]),
        currency: params[:currency],
        description: "ApplePay test recurring payment",
        tracking_id: "apple_pay_test_tracking_id",
        test: true,
        billing_address: {
          first_name: "John",
          last_name: "Doe",
          country: "US",
          city: "Denver",
          state: "CO",
          zip: "96002",
          address: "1st Street"
        },
        credit_card: {
          token: params[:token]
        },
        customer: {
          ip: "127.0.0.1",
          email: "john@example.com"
        }
      }
    }
    commit('payment', data)
  end

  def close_day
    data = {
      gateway_id: params[:gateway_id],
      ccy: params[:currency]
    }
    commit('close_days', data)
  end

  private

  def commit(type, data)
    response = connection.public_send(type, data)
    if response&.transaction&.successful?
      result  = case type
                when 'capture' then 'captured'
                when 'void'    then 'voided'
                when 'refund'  then 'refunded'
                when 'payment' then 'paid'
                end
      message = "#{params[:parent_uid]}: #{params[:amount]} #{response.transaction.currency} was successfully #{result}"
      render json: { status: 200, message: message }
    else
      render json: { status: response.status, message: response.message }
    end
  rescue NoMethodError
    if type == 'close_days'
      render json: { status: 200, message: 'Settlement was successfully processed' }
    else
      raise 'Settlement error'
    end
  rescue => error
    render json: { status: 500, message: error.message }
  end

  def money_format(amount)
    amount.to_i * 100
  end

  def connection
    @connection ||= BeGateway::Client.new(
      shop_id: 1,
      secret_key: '0a3d7a695183b575a51afff999202600d818aac78af25e712649708a4a596a54',
      url: 'https://demo-gateway-staging.begateway.com'
    )
  end
end
