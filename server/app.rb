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
    ensure_login_user_except(['users'])
  end

  get '/' do
    p @user.store.username
    redirect local_url("/users/#{@user.store.username}/myboard");
  end

  get '/users/*/*' do |username, boardname|
    target = User.store_class.find_by_username(username) or go_to_login_page
    board = target.find_board(boardname) or go_to_login_page
    erb :board, :locals => { :current_board => board, :boards => @user.store.boards }
  end
end
