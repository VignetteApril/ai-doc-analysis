Rails.application.routes.draw do
  get "home/dashboard"
  # 登录/退出
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # 演示一个登录后页面
  get "dashboard", to: "home#dashboard"

  # root "sessions#new"

  resources :documents, only: [ :show, :create, :new ] do
    member do
      post :analyze
    end
  end
  root "documents#new"
end
