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
  set :public_folder, "#{File.dirname(__FILE__)}/public"
  
  include WebServerHelper
  def here; ""; end

  before do
    @user = User.attach_if_exist(session['user_id'])
    redirect "#{URL_PREFIX}/account/login", 303 unless @user
  end

  get '/' do
    erb :mypage, :locals => { :user => @user }
  end

  get '/user/*' do |username|
    user = User.store_class.find_by_username(username) or halt 404
    erb :userpage, :locals => { :user => user }
  end

  get '/p/user_timeline' do
    render_root(@user)
  end

  post '/p/newarticle' do
    @user.add_post(params[:content])
    render_root(@user)
  end

  post '/p/newcomment' do
    post = Post.attach_if_exist(params[:parent].to_i) or halt 403
    @user.add_comment(post, params[:content])
    render_root(@user)
  end

  get '/p/favor' do
    post = Post.attach_if_exist(params[:target].to_i) or halt 403
    @user.toggle_favorite(post)
    redirect local_url('/')
  end

  get %r{/static/(.*)\.css} do |path|
    scss :"#{path}"
  end

  get %r{/static/(.*\.(js|css|png|gif))} do |path, ext|
    send_file File.join(settings.public_folder, path)
  end

  private
  def render_root(user)
    erb :_timeline, :locals => { :user => user, :timeline => user.store.primary_timeline, :comment => :enabled, :direction => :upward }
  end

end
