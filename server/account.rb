# -*- coding: utf-8 -*-

class Account < Sinatra::Base
  helpers WebServerHelper

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
      username, password = params.values_at(:username, :password)
      user = User.create(username, password)
      session["user_id"] = user.store.id
      redirect parent_url("/users/#{username}/myboard")
    rescue SignUpError => e
      puts e.backtrace
      puts e
      render_login_page(nil, e.to_s)
    end
  end
  
  post '/login' do
    username, password = params.values_at(:username, :password)
    if user = User.auth(username, password)
      session["user_id"] = user.store.id
      redirect parent_url("/users/#{username}/myboard")
    else
      render_login_page("bad username or password", nil)
    end
  end

end
