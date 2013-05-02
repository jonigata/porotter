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
    redirect local_url("/users/#{@user.store.username}/マイボード");
  end

  get '/logout' do
    session["user_id"] = nil
    go_to_login_page
  end

  get '/users/*/*' do |username, boardname|
    halt 403 if !@user
    puts "**************** refered"
    refered = User.store_class.find_by_username(username) or go_to_login_page
    puts "**************** board"
    board = refered.find_board(boardname) or go_to_login_page
    puts "done"
    erb :board, :locals => { :base_url => local_url("/users"), :refered => refered, :current_board => board, :boards => refered.store.boards }
  end
end
