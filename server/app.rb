# -*- coding: utf-8 -*-

require 'sinatra/rocketio'

require_relative 'notifiee'

class Porotter < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::RocketIO

  helpers Sinatra::Jsonp
  helpers WebServerHelper

  configure do
    start_watch
  end

  before do
    ensure_login_user_except(['user', 'p', 'static'])
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
    # symbol leak対策のためinternしない
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
