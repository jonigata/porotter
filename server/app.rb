# -*- coding: utf-8 -*-

require 'sinatra/rocketio'

require_relative 'notifiee'

$timeline_notifiee = Notifiee.new
$post_notifiee = Notifiee.new

class Porotter < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::RocketIO

  helpers Sinatra::Jsonp

  configure :development do
    register Sinatra::Reloader
    also_reload "#{File.dirname(__FILE__)}/*.rb"
    also_reload "#{File.dirname(__FILE__)}/models/*.rb"
  end

  configure do
    io = Sinatra::RocketIO
    io.on :connect do |session, type|
      puts "new client <#{session}> (type:#{type})"
    end

    io.on :disconnect do |session, type|
      puts "delete client <#{session}> (type:#{type})"
      $timeline_notifiee.remove_session(session)
      $post_notifiee.remove_session(session)
    end

    io.on :'watch-timeline' do |data, session, type|
      # puts "watch-timeline params: #{data}, <#{session}> type: #{type}"
      $timeline_notifiee.set_targets(session, data)
    end

    io.on :'watch-post' do |data, session, type|
      # puts "watch-post params: #{data}, <#{session}> type: #{type}"
      $post_notifiee.set_targets(session, data)
    end
      

    EM.defer do
      Redis.new.subscribe("timeline-watcher", "post-watcher") do |on|
        on.message do |channel, message|
          case channel
          when "timeline-watcher"
            # puts "get timeline-watcher singal(#{message})"
            EM.next_tick do
              $timeline_notifiee.trigger(message) do |timeline_id, version, session|
                # puts "send timeline watch message: #{timeline_id}"
                io.push :'watch-timeline', {:timeline => timeline_id, :version => version}, {:to => session }
              end
            end
          when "post-watcher"
            # puts "get post-watcher singal(#{message})"
            EM.next_tick do
              $post_notifiee.trigger(message) do |post_id, version, session|
                # puts "send post watch message: #{post_id}"
                io.push :'watch-post', {:post => post_id, :version => version}, {:to => session }
              end
            end
          end
        end
      end
    end
  end

  enable :sessions
  set :session_secret, 'porotter secret'
  set :public_folder, "#{File.dirname(__FILE__)}/public"
  
  include WebServerHelper
  def here; ""; end

  before do
    @user = User.attach_if_exist(session['user_id'])
    s = request.path_info.split('/')[1]
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
    timeline = Timeline.attach_if_exist(params['timeline'].to_i) or halt 403
    level = params['level'].to_i or halt 403
    JSONP(make_timeline_data(timeline, level))
  end

  get '/p/detail' do
    post = Post.attach_if_exist(params[:post].to_i) or halt 403
    JSONP(make_detail_data(post))
  end

  post '/m/newarticle' do
    @user.add_article(params[:content])
    "OK"
  end

  post '/m/newcomment' do
    post = Post.attach_if_exist(params[:parent].to_i) or halt 403
    @user.add_comment(post, params[:content])
    "OK"
  end

  get '/m/favor' do
    post = Post.attach_if_exist(params[:target].to_i) or halt 403
    @user.toggle_favorite(post)
    "OK"
  end

  get %r{/static/(.*)\.css} do |path|
    scss :"#{path}"
  end

  get %r{/static/(.*\.(js|css|png|gif))} do |path, ext|
    send_file File.join(settings.public_folder, path)
  end

  private
  def symbolize(s, candidates)
    candidates.each do |c|
      return c if c.to_s == s
    end
    return nil
  end

  def display_post_content(content)
    if content == ''
      "<span class='deleted'>この投稿は削除されています</span>"
    else
      Sanitize.clean(content).gsub(URI.regexp) do |uri|
        "<a class='external-link' href='#{uri}' target='_blank'>#{uri}</a>"
      end
    end
  end

  def make_detail_data(post)
    comments = post.store.comments;
    author = post.store.author
    {
      :commentsId => comments.store.id,
      :commentsLength => comments.length,
      :commentsVersion => comments.store.version,
      :authorLabel => author.store.label,
      :authorUsername => author.store.username,
      :favoredBy => post.store.favored_by.map {
        |x| Misc.gravator(x.store.email)
      },
      :userExists => (@user ? true : false),
      :postId => post.store.id,
      :favorLabel => @user ? (@user.favors?(post) ? 'そうでもない' : 'そうかも') : '',
      :content => display_post_content(post.store.content)
    }
  end

  def make_timeline_data(timeline, level)
    {
      :level => level,
      :timelineId => timeline.store.id,
      :timelineVersion => timeline.store.version,
      :posts => timeline.fetch_all(:upward).map do |post|
        detail = make_detail_data(post)
        {
          :postId => post.store.id,
          :postVersion => post.store.version,
          :icon => Misc.gravator(post.store.author.store.email),
          :detail => detail,
          :commentsId => detail[:commentsId],
          :commentsLength => detail[:commentsLength],
          :commentsVersion => detail[:commentsVersion],
          :comments => [],
          :userExists => @user ? true : false,
          :chatIconUrl => local_url('/images/chat.png')
        }
      end,
    }
  end

end
