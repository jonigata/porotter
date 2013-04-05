# -*- coding: utf-8 -*-

require 'sinatra/rocketio'

require_relative 'notifiee'

class Porotter < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::RocketIO

  helpers WebServerHelper

  configure do
    start_watch
  end

  before do
    ensure_login_user_except(['user'])
  end

  get '/' do
    erb :mypage, :locals => { :board => @user.store.board }
  end

  get "/user/all" do
    erb :allpage
  end

  get '/user/*' do |username|
    target = User.store_class.find_by_username(username) or halt 404
    erb :userpage, :locals => { :target => target }
  end
end
