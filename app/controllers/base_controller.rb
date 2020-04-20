class BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, except: :index

  GW_HOST = 'https://gateway.bepaid.by'
  CTP_HOST = 'https://checkout.bepaid.by'
  HEROKU_HOST = 'https://ecomcharge-applepay.herokuapp.com'
  DEMO_SHOP_ID = 10053
  DEMO_SHOP_SECRET_KEY = '4e549e819a7d1dd5f6bc05a0941d63df6d80cf96c400bf3c86916666d916d89e'

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
      amount: money_format(params[:amount]),
      currency: params[:currency],
      description: "ApplePay test recurring #{params[:txn_type]}",
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
    commit(params[:txn_type], data, true)
  end

  def close_day
    data = {
      gateway_id: params[:gateway_id],
      ccy: params[:currency]
    }
    commit('close_days', data)
  end

  def credit_card_token
    if params[:uid].present?
      response = JSON.parse(gw_faraday_connection.get("#{GW_HOST}/transactions/#{params[:uid]}").body)
      cc_token = response.dig('transaction', 'credit_card', 'token')
      txn_type = response.dig('transaction', 'type')

      render json: { status: 200, credit_card_token: cc_token, txn_type: txn_type }
    end
  rescue JSON::ParserError, TypeError
    render json: { status: 500, message: 'Unable to parse Gateway response' }
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
          return_url: "#{HEROKU_HOST}/#{params[:locale]}",
          language: params[:locale]
        }
      }
    }

    response = ctp_connection.post("#{CTP_HOST}/ctp/api/checkouts", data.to_json)
    response = JSON.parse(response.body)['checkout']
    redirect_to "https://#{URI(response['redirect_url']).host}/widget/hpp.html?token=#{response['token']}"
  rescue Faraday::ConnectionFailed => error
    render json: { status: 500, message: error.message }
  rescue JSON::ParserError, TypeError
    render json: { status: 500, message: 'Unable to parse CTP response' }
  rescue => error
    render json: { status: 500, message: error.message }
  end

  def commit(type, data, recurring = false)
    response = gw_connection.public_send(type, data)
    if response&.transaction&.successful?
      if recurring
        redirect_to "#{root_url}/#{locale}?uid=#{response.transaction.uid}&status=#{response.transaction.status}"
      else
        result = case type
                 when 'capture'       then 'captured'
                 when 'void'          then 'voided'
                 when 'refund'        then 'refunded'
                 when 'payment'       then 'paid'
                 when 'authorization' then 'authorized'
                 end
        message = "#{params[:parent_uid]} | #{params[:amount]} #{response.transaction.currency} was successfully #{result}"
        render json: { status: 200, message: message }
      end
    else
      render json: { status: response.status, message: response.transaction.message || response.message }
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
      url: GW_HOST
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

  def gw_faraday_connection
    @ctp_connection ||= Faraday::Connection.new(ssl: { verify: false }) do |c|
      c.options[:open_timeout] = 10
      c.options[:timeout] = 30
      c.request(:basic_auth, DEMO_SHOP_ID, DEMO_SHOP_SECRET_KEY)
      c.adapter(Faraday.default_adapter)
    end
  end
end
