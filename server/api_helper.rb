# -*- coding: utf-8 -*-

module APIHelper
  def self.included(klass)
    klass.class_eval do
      get '/v/timeline' do
        r = ensure_params(
          :timeline => [/[0-9]+/, Integer],
          :newest_score => [/[0-9]+/, nullable(Integer)],
          :oldest_score => [/[0-9]+/, nullable(Integer)],
          :count => [/[0-9]+/, Integer])
        p r
        get_timeline(r.timeline, r.newest_score, r.oldest_score, r.count)
      end

      get '/v/detail' do
        r = ensure_params(
          :post => [/[0-9]+/, Integer])
        get_detail(r.post)
      end

      post '/m/newarticle' do
        post_new_article(params[:content])
      end

      post '/m/newcomment' do
        r = ensure_params(
          :parent => [/[0-9]+/, Integer])
        post_new_comment(r.parent, :Tweet, params[:content])
      end

      post '/m/favor' do
        r = ensure_params(
          :target => [/[0-9]+/, Integer])
        favor(r.target)
        "OK"
      end

      post '/m/stamp' do
        r = ensure_params(
          :parent => [/[0-9]+/, Integer])
        post_new_comment(r.parent, :Stamp, params[:content])
      end
    end
  end
  
  private
  def get_timeline(timeline_id, newest_score, oldest_score, count)
    timeline = Timeline.attach_if_exist(timeline_id) or raise
    JSONP(make_timeline_data(timeline, newest_score, oldest_score, count))
  end

  def get_detail(post_id)
    post = Post.attach_if_exist(post_id) or raise
    JSONP(make_detail_data(post))
  end

  def post_new_article(content)
    @user.add_article(:Tweet, content).store.id.to_s
  end

  def post_new_comment(parent_id, type, content)
    parent = Post.attach_if_exist(parent_id) or raise
    @user.add_comment(parent, type, params[:content]).store.id.to_s
  end

  def favor(target_id)
    post = Post.attach_if_exist(target_id) or raise
    @user.toggle_favorite(post)
  end

  def ensure_params(h)
    halt_on_exception do
      params.enstructure(h)
    end
  end

  def halt_on_exception(code = 403)
    begin
      yield
    rescue => e
      puts e
      halt code
    end
  end

  def make_detail_data(post)
    comments = post.store.comments;
    author = post.store.author
    content = PlugIns.module_eval(post.type.to_s).display(
      PluginService.new(settings), post)
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
      :content => content
    }
  end

  def make_timeline_data(timeline, newest_score, oldest_score, count)
    posts, res_newest_score, res_oldest_score = timeline.fetch(
      newest_score, oldest_score, count)
    {
      :timelineId => timeline.store.id,
      :timelineVersion => timeline.store.version,
      :newestScore => res_newest_score,
      :oldestScore => res_oldest_score,
      :posts => posts.map do |h|
        score, post = h.values_at(:score, :value)
        detail = make_detail_data(post)
        {
          :score => score,
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

