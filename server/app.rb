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
    p request.path_info
    s = request.path_info.split('/')[1]
    p s
    if !@user && s != 'user' && s != 'p' && s != 'static'
      redirect "#{URL_PREFIX}/account/login", 303
    end
  end

  get '/' do
    # erb :mypage
    erb :allpage
  end

  get "/user/all" do
    erb :allpage
  end

  get '/user/*' do |username|
    target = User.store_class.find_by_username(username) or halt 404
    erb :userpage, :locals => { :target => target }
  end

  get '/p/timeline' do
    render_root(Timeline.attach_if_exist(params['timeline'].to_i))
  end

  post '/m/newarticle' do
    @user.add_post(params[:content])
    render_root(Timeline.attach_if_exist(params['timeline'].to_i))
  end

  post '/m/newcomment' do
    p params[:content]
    post = Post.attach_if_exist(params[:parent].to_i) or halt 403
    @user.add_comment(post, params[:content])
    render_root(Timeline.attach_if_exist(params['timeline'].to_i))
  end

  get '/m/favor' do
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
  def render_root(timeline)
    halt 403 unless timeline
    erb :_timeline, :locals => { :user => @user, :root => timeline, :timeline => timeline, :comment => :enabled, :direction => :upward }
  end

end
