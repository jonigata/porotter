# -*- coding: utf-8 -*-

module APIHelper
  def self.included(klass)
    klass.class_eval do
      get '/v/timeline' do
        r = ensure_params(
          :ribbon => [/[0-9]+/, Integer],
          :timeline => [/[0-9]+/, Integer],
          :newest_score => [/[0-9]+/, nullable(Integer)],
          :oldest_score => [/[0-9]+/, nullable(Integer)],
          :count => [/[0-9]+/, Integer])
        get_timeline(
          r.ribbon, r.timeline, r.newest_score, r.oldest_score, r.count)
      end

      get '/v/detail' do
        r = ensure_params(
          :ribbon => [/[0-9]+/, Integer],
          :post => [/[0-9]+/, Integer])
        get_detail(r.ribbon, r.post)
      end

      post '/m/newarticle' do
        r = ensure_params(:ribbon => [/[0-9]+/, Integer])
        post_new_article(r.ribbon, params[:content])
      end

      post '/m/newcomment' do
        r = ensure_params(
          :ribbon => [/[0-9]+/, Integer],
          :parent => [/[0-9]+/, Integer])
        post_new_comment(r.ribbon, r.parent, :Tweet, params[:content])
      end

      post '/m/favor' do
        r = ensure_params(
          :ribbon => [/[0-9]+/, Integer],
          :target => [/[0-9]+/, Integer])
        favor(r.ribbon, r.target)
        "OK"
      end

      post '/m/unfavor' do
        r = ensure_params(
          :ribbon => [/[0-9]+/, Integer],
          :target => [/[0-9]+/, Integer])
        unfavor(r.ribbon, r.target)
        "OK"
      end

      post '/m/stamp' do
        r = ensure_params(
          :ribbon => [/[0-9]+/, Integer],
          :parent => [/[0-9]+/, Integer])
        post_new_comment(r.ribbon, r.parent, :Stamp, params[:content])
      end
    end
  end
  
  private
  def get_timeline(ribbon_id, timeline_id, newest_score, oldest_score, count)
    # TODO: @userがribbonにアクセス権を持っているかどうかのチェック
    # TODO: timelineがribbonに所属しているかどうかのチェック
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    timeline = Timeline.attach_if_exist(timeline_id) or raise
    JSONP(make_timeline_data(
        ribbon, timeline, newest_score, oldest_score, count))
  end

  def get_detail(ribbon_id, post_id)
    # TODO: @userがribbonにアクセス権を持っているかどうかのチェック
    # TODO: timelineがribbonに所属しているかどうかのチェック
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    post = Post.attach_if_exist(post_id) or raise
    JSONP(make_detail_data(ribbon, post))
  end

  def post_new_article(ribbon_id, content)
    ribbon = Ribbon.attach_if_exist(ribbon_id)
    @user.add_article(ribbon, :Tweet, content).store.id.to_s
  end

  def post_new_comment(ribbon_id, parent_id, type, content)
    ribbon = Ribbon.attach_if_exist(ribbon_id)
    parent = Post.attach_if_exist(parent_id) or raise
    @user.add_comment(ribbon, parent, type, params[:content]).store.id.to_s
  end

  def favor(ribbon_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id)
    post = Post.attach_if_exist(target_id) or raise
    @user.favor(ribbon, post)
  end

  def unfavor(ribbon_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id)
    post = Post.attach_if_exist(target_id) or raise
    @user.unfavor(ribbon, post)
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

  def make_detail_data(ribbon, post)
    comments = post.store.comments;
    author = post.store.author
    content = PlugIns.module_eval(post.type.to_s).display(
      PluginService.new(settings), post)
    {
      :ribbonId => ribbon.store.id,
      :commentsId => comments ? comments.store.id : 0,
      :commentsLength => comments ? comments.length : 0,
      :commentsVersion => comments ? comments.store.version : 0,
      :authorLabel => author.store.label,
      :authorUsername => author.store.username,
      :favoredBy => post.store.favored_by.map {
        |x| Misc.gravator(x.store.email)
      },
      :userExists => (@user ? true : false),
      :postId => post.store.id,
      :favored => @user ? @user.favors?(post) : '',
      :content => content
    }
  end

  def make_timeline_data(ribbon, timeline, newest_score, oldest_score, count)
    posts, res_newest_score, res_oldest_score = timeline.fetch(
      newest_score, oldest_score, count)
    {
      :ribbonId => ribbon.store.id,
      :timelineId => timeline.store.id,
      :timelineVersion => timeline.store.version,
      :newestScore => res_newest_score,
      :oldestScore => res_oldest_score,
      :posts => posts.map do |h|
        score, post = h.values_at(:score, :value)
        detail = make_detail_data(ribbon, post)
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

