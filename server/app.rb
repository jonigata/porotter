# -*- coding: utf-8 -*-

require 'sinatra/rocketio'

require_relative 'notifiee'

class Porotter < Sinatra::Base
  register Sinatra::RocketIO

  helpers Sinatra::Jsonp
  helpers WebServerHelper

  configure do
    start_watch
  end

  before do
    ensure_login_user_except(['users', 'logout'])
  end

  get '/' do
    p @user.store.username
    redirect local_url("/users/#{@user.store.username}/myboard");
  end

  get '/logout' do
    session["user_id"] = nil
    go_to_login_page
  end

  get '/users/*/*' do |username, boardname|
    halt 403 if !@user
    owner = User.store_class.find_by_username(username) or go_to_login_page
    board = owner.find_board(boardname) or go_to_login_page
    erb :board, :locals => { :owner => owner, :current_board => board, :boards => owner.store.boards }
  end
end
