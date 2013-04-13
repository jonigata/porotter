# -*- coding: utf-8 -*-

module APIHelper
  INT_PARAM           = [/[0-9]+/, Integer]
  NULLABLE_INT_PARAM  = [/[0-9]+/, nullable(Integer)]
  IDNAME_PARAM        = [/[0-9a-zA-Z_]+/, String]

  def self.included(klass)
    klass.class_eval do
      get '/v/timeline' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :timeline => INT_PARAM,
          :newest_score => NULLABLE_INT_PARAM,
          :oldest_score => NULLABLE_INT_PARAM,
          :count => INT_PARAM)
        get_timeline(
          r.ribbon, r.timeline, r.newest_score, r.oldest_score, r.count)
      end

      get '/v/detail' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :post => INT_PARAM)
        get_detail(r.ribbon, r.post)
      end

      get '/v/userlist' do
        get_userlist
      end

      get '/v/grouplist' do
        get_grouplist
      end

      get '/v/boardlist' do
        r = ensure_params(
          :user => INT_PARAM)
        get_boardlist(r.user)
      end

      post '/m/newarticle' do
        r = ensure_params(:ribbon => INT_PARAM)
        post_new_article(r.ribbon, params[:content])
      end

      post '/m/newcomment' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :parent => INT_PARAM)
        post_new_comment(r.ribbon, r.parent, :Tweet, params[:content])
      end

      post '/m/favor' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :target => INT_PARAM)
        favor(r.ribbon, r.target)
        "OK"
      end

      post '/m/unfavor' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :target => INT_PARAM)
        unfavor(r.ribbon, r.target)
        "OK"
      end

      post '/m/stamp' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :parent => INT_PARAM)
        post_new_comment(r.ribbon, r.parent, :Stamp, params[:content])
        "OK"
      end

      post '/m/newboard' do
        r = ensure_params(
          :name => IDNAME_PARAM)
        make_new_board(r.name, params[:label])
        redirect parent_url("/users/#{@user.store.username}/#{r.name}")
      end

      post '/m/newribbon' do
        r = ensure_params(
          :board => INT_PARAM)
        board_name = make_new_ribbon(r.board, params[:label])
        redirect parent_url("/users/#{@user.store.username}/#{board_name}")
      end

      post '/m/closeribbon' do
        r = ensure_params(
          :ribbon => INT_PARAM)
        close_ribbon(r.ribbon)
        "OK"
      end

      post '/m/editpermission' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :permission => [/(private|public)/, Symbol])
        board_name = edit_permission(r.ribbon, r.permission)
        redirect parent_url("/users/#{@user.store.username}/#{board_name}")
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

  def get_userlist
    JSONP(
      Users.singleton.list.map do |user|
        [user.store.id, user.store.username, user.store.label]
      end)
  end

  def get_grouplist
    JSONP(
      Groups.singleton.list.map do |group|
        [group.store.id, group.store.name]
      end)
  end

  def get_boardlist(target_id)
    target = User.attach_if_exist(target_id) or raise
    JSONP(
      target.store.boards.map do |boardname, board|
        [board.store.id, boardname, board.store.label]
      end)
  end

  def post_new_article(ribbon_id, content)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    @user.add_article(ribbon, :Tweet, content).store.id.to_s
  end

  def post_new_comment(ribbon_id, parent_id, type, content)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    parent = Post.attach_if_exist(parent_id) or raise
    @user.add_comment(ribbon, parent, type, params[:content]).store.id.to_s
  end

  def favor(ribbon_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    post = Post.attach_if_exist(target_id) or raise
    @user.favor(ribbon, post)
  end

  def unfavor(ribbon_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    post = Post.attach_if_exist(target_id) or raise
    @user.unfavor(ribbon, post)
  end

  def make_new_board(name, label)
    @user.add_board(name, label)
  end

  def make_new_ribbon(board_id, label)
    board = Board.attach_if_exist(board_id) or false
    @user.add_ribbon(board, label)
    board.store.name
  end

  def close_ribbon(ribbon_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    @user.remove_ribbon(ribbon)
  end

  def edit_permission(ribbon_id, permission)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    @user.edit_permission(ribbon, permission)
    ribbon.store.owner.store.name
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

