# -*- coding: utf-8 -*-

class Porotter < Sinatra::Base
  register Sinatra::Namespace

  configure :development do
    register Sinatra::Reloader
    also_reload "#{File.dirname(__FILE__)}/*.rb"
    also_reload "#{File.dirname(__FILE__)}/models/*.rb"
  end

  enable :sessions
  set :session_secret, 'porotter secret'
  
  before do
    p session['user_id']
    redirect "#{URL_PREFIX}/account/login", 303 unless session['user_id']
  end

  get '/' do
    "session_id = '#{session['user_id']}'"
  end
end
