# -*- coding: utf-8 -*-

class Account < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    also_reload "#{File.dirname(__FILE__)}/*.rb"
    also_reload "#{File.dirname(__FILE__)}/models/*.rb"
  end

  enable :sessions
  set :session_secret, 'porotter secret'
  
  include WebServerHelper
  def here; "/account"; end

  get '' do
    "ROOT"
  end

  get '/login' do
    render_login_page(nil, nil)
  end

  get '/logout' do
    "LOGOUT"
  end

  post '/signup' do
    begin
      user = User.create(*params.values_at(:username, :password))
      session["user_id"] = user.store.id
      redirect parent_url("/")
    rescue SignUpError => e
      puts e
      render_login_page(nil, e.to_s)
    end
  end
  
  post '/login' do
    if user = User.auth(*params.values_at(:username, :password))
      session["user_id"] = user.store.id
      redirect parent_url("/")
    else
      render_login_page("bad username or password", nil)
    end
  end

end
