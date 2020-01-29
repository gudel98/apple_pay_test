Rails.application.routes.draw do
  get  'base/index'
  root 'base#index'

  post '/refund', to: 'base#refund'
end
