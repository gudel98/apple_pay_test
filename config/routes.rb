Rails.application.routes.draw do
  get '/:locale', to: 'base#index', constraints: { locale: /(be|ru|en|da|de|es|fi|fr|it|ja|ka|no|pl|ro|sv|tr|zh)/ }
  root 'base#index'

  get '/docs', to: 'base#docs'

  post '/authorization', to: 'base#authorization'
  post '/payment',   to: 'base#payment'
  post '/capture',   to: 'base#capture'
  post '/void',      to: 'base#void'
  post '/refund',    to: 'base#refund'
  post '/recurring', to: 'base#recurring'
  post '/close_day', to: 'base#close_day'
  post '/credit_card_token', to: 'base#credit_card_token'
end
