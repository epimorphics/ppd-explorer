# frozen_string_literal: true

PpdExplorer::Application.routes.draw do
  root 'ppd#index'

  resources :ppd, only: [:index]
  resources :search
  resource :ppd_data

  get '*unmatched_route', to: 'application#render_404'
end
