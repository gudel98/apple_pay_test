Rails.application.routes.draw do
  get  'base/index'
  root 'base#index'

  post '/capture',   to: 'base#capture'
  post '/void',      to: 'base#void'
  post '/refund',    to: 'base#refund'
  post '/recurring', to: 'base#recurring'
  post '/close_day', to: 'base#close_day'
end
