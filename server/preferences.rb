# -*- coding: utf-8 -*-

class Preferences < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    also_reload "#{File.dirname(__FILE__)}/*.rb"
    also_reload "#{File.dirname(__FILE__)}/models/*.rb"
  end

  enable :sessions
  set :session_secret, 'porotter secret'
  
  include WebServerHelper
  def here; "/preferences"; end

  before do
    @user = User.attach_if_exist(session['user_id'])
    s = request.path_info.split('/')[1]
    if !@user
      redirect "#{URL_PREFIX}/account/login", 303
    end
  end

  get '/' do
    erb :preferences
  end

  get '/edit_label' do
    puts params['label']
    @user.store.label = params['label']
    redirect local_url('/')
  end
  
  get '/edit_email' do
    puts params['email']
    @user.store.email = params['email']
    redirect local_url('/')
  end
  

end
