class BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, except: :index

  DEMO_SHOP_ID = 29
  DEMO_SHOP_SECRET_KEY = 'f1814518ba6451bd85d961480c9387b482bda215decb8ae5ca6b86f80d1e868b'

  def index
    I18n.locale = params[:locale] || I18n.default_locale
    @result = params
  end

  def docs
  end

  def authorization
    redirect_with_token
  end

  def payment
    redirect_with_token
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
        description: 'ApplePay test recurring payment',
        tracking_id: 'apple_pay_test_tracking_id',
        test: false,
        billing_address: {
          first_name: 'John',
          last_name: 'Doe',
          country: 'US',
          city: 'Denver',
          state: 'CO',
          zip: '96002',
          address: '1st Street'
        },
        credit_card: {
          token: params[:token]
        },
        customer: {
          ip: '127.0.0.1',
          email: 'john@example.com'
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

  def redirect_with_token
    data = {
      checkout: {
        test: false,
        transaction_type: params[:txn_type],
        order: {
          amount: money_format(params[:amount]),
          currency: params[:currency],
          description: "ApplePay test #{params[:txn_type]}"
        },
        customer: {},
        settings: {
          return_url: "https://ecomcharge-applepay.herokuapp.com/#{params[:locale]}",
          language: params[:locale]
        }
      }
    }

    response = ctp_connection.post('https://checkout-staging.begateway.com/ctp/api/checkouts', data.to_json)
    response = JSON.parse(response.body)['checkout']
    redirect_to "https://#{URI(response['redirect_url']).host}/widget/hpp.html?token=#{response['token']}"
  rescue Faraday::ConnectionFailed => error
    render json: { status: 500, message: error.message }
  rescue JSON::ParserError, TypeError
    render json: { status: 500, message: 'Unable to parse CTP response' }
  rescue => error
    render json: { status: 500, message: error.message }
  end

  def commit(type, data)
    response = gw_connection.public_send(type, data)
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

  def gw_connection
    @gw_connection ||= BeGateway::Client.new(
      shop_id: DEMO_SHOP_ID,
      secret_key: DEMO_SHOP_SECRET_KEY,
      url: 'https://demo-gateway-staging.begateway.com'
    )
  end

  def ctp_connection
    @ctp_connection ||= Faraday::Connection.new(ssl: { verify: false }) do |c|
      c.headers['Content-Type'] = 'application/json'
      c.headers['X-Api-Version'] = '2.1'
      c.options[:open_timeout] = 5
      c.options[:timeout] = 20
      c.request(:basic_auth, DEMO_SHOP_ID, DEMO_SHOP_SECRET_KEY)
      c.adapter(Faraday.default_adapter)
    end
  end
end
