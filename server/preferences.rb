# -*- coding: utf-8 -*-

class Preferences < Sinatra::Base
  helpers WebServerHelper

  before do
    ensure_login_user_except([])
  end

  get '/' do
    erb :preferences
  end

  get '/edit_label' do
    @user.store.label = params['label']
    redirect local_url('/')
  end
  
  get '/edit_email' do
    @user.store.email = params['email']
    redirect local_url('/')
  end

end
