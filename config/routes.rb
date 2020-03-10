Rails.application.routes.draw do
  get  'base/index'
  root 'base#index'

  get '/docs', to: 'base#docs'

  post '/authorization', to: 'base#authorization'
  post '/payment',   to: 'base#payment'
  post '/capture',   to: 'base#capture'
  post '/void',      to: 'base#void'
  post '/refund',    to: 'base#refund'
  post '/recurring', to: 'base#recurring'
  post '/close_day', to: 'base#close_day'
end
