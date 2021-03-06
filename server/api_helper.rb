# -*- coding: utf-8 -*-

module APIHelper
  INT_PARAM           = [/[0-9]+/, Integer]
  NULLABLE_INT_PARAM  = [/[0-9]+/, nullable(Integer)]
  IDNAME_PARAM        = [/[0-9a-zA-Z_]+/, String]

  def self.included(klass)
    klass.class_eval do
      get '/v/workspace' do
        r = ensure_params(
          :user => INT_PARAM,
          :board => INT_PARAM);
        get_workspace(r.user, r.board)
      end

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

      get '/v/group' do
        r = ensure_params(
          :group => INT_PARAM)
        get_group(r.group)
      end

      get '/v/userlist' do
        get_userlist
      end

      get '/v/grouplist' do
        get_grouplist
      end

      get '/v/memberlist' do
        r = ensure_params(
          :group => INT_PARAM)
        get_memberlist(r.group)
      end

      get '/v/boardlist' do
        r = ensure_params(
          :user => INT_PARAM)
        get_boardlist(r.user)
      end

      get '/v/ribbonlist' do
        r = ensure_params(
          :board => INT_PARAM)
        get_ribbonlist(r.board)
      end

      get '/v/removedribbonlist' do
        r = ensure_params(
          :board => INT_PARAM)
        get_removedribbonlist(r.board)
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

      post '/m/stamp' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :parent => INT_PARAM)
        post_new_comment(r.ribbon, r.parent, :Stamp, params[:content])
        "OK"
      end

      post '/m/movearticle' do
        r = ensure_params(
          :ribbon => INT_PARAM,
          :source => INT_PARAM,
          :target => INT_PARAM)
        move_article(r.ribbon, r.source, r.target)
        "OK"
      end

      post '/m/transferarticle' do
        r = ensure_params(
          :source_ribbon => INT_PARAM,
          :target_ribbon => INT_PARAM,
          :source => INT_PARAM,
          :target => INT_PARAM)
        transfer_article(r.source_ribbon, r.target_ribbon, r.source, r.target)
        "OK"
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

      post '/m/newboard' do
        make_new_board(params[:label])
      end

      post '/m/joinboard' do
        r = ensure_params(
          :board => INT_PARAM)
        join_board(r.board)
      end

      post '/m/newribbon' do
        r = ensure_params(
          :board => INT_PARAM)
        make_new_ribbon(r.board, params[:label])
      end

      post '/m/joinribbon' do
        r = ensure_params(
          :target => INT_PARAM,
          :ribbon => INT_PARAM)
        join_ribbon(r.target, r.ribbon)
      end

      post '/m/restoreribbon' do
        r = ensure_params(
          :target => INT_PARAM,
          :ribbon => INT_PARAM)
        restore_ribbon(r.target, r.ribbon)
      end

      post '/m/closeribbon' do
        r = ensure_params(
          :board => INT_PARAM,
          :ribbon => INT_PARAM)
        close_ribbon(r.board, r.ribbon)
      end

      post '/m/modifyboardsettings' do
        r = ensure_params(
          :board => INT_PARAM,
          :read_permission => [[:everyone, :public_group, :private_group], Symbol],
          :write_permission => [[:everyone, :public_group, :private_group, :same_as_read], Symbol],
          :edit_permission => [[:everyone, :public_group, :private_group, :same_as_read, :same_as_write], Symbol],

          # 以下数値か数値の配列
          :readable_group => [/(\[[0-9,]*\])|([0-9]+)/, String],
          :writable_group => [/(\[[0-9,]*\])|([0-9]+)/, String],
          :editable_group => [/(\[[0-9,]*\])|([0-9]+)/, String]
          )
        
        modify_board_settings(
          r.board,
          params[:board_label],
          r.read_permission,
          r.write_permission,
          r.edit_permission,
          JSON.parse(r.readable_group),
          JSON.parse(r.writable_group),
          JSON.parse(r.editable_group));
      end
      
      post '/m/modifyribbonsettings' do
        r = ensure_params(
          :board => INT_PARAM,
          :ribbon => INT_PARAM,
          :read_permission => [[:everyone, :public_group, :private_group, :same_as_board], Symbol],
          :write_permission => [[:everyone, :public_group, :private_group, :same_as_read, :same_as_board], Symbol],
          :edit_permission => [[:everyone, :public_group, :private_group, :same_as_read, :same_as_writ, :same_as_board], Symbol],

          # 以下数値か数値の配列
          :readable_group => [/(\[[0-9,]*\])|([0-9]+)/, String],
          :writable_group => [/(\[[0-9,]*\])|([0-9]+)/, String],
          :editable_group => [/(\[[0-9,]*\])|([0-9]+)/, String]
          )
        
        modify_ribbon_settings(
          r.board,
          r.ribbon,
          params[:ribbon_label],
          r.read_permission,
          r.write_permission,
          r.edit_permission,
          JSON.parse(r.readable_group),
          JSON.parse(r.writable_group),
          JSON.parse(r.editable_group));
      end
      
      post '/m/ribbontest' do
        r = ensure_params(
          :ribbon => INT_PARAM)
        do_ribbon_test(r.ribbon)
      end
    end
  end
  
  private
  def get_workspace(user_id, board_id)
    user = User.attach_if_exist(user_id) or raise
    board = Board.attach_if_exist(board_id) or raise

    erb :_workspace, :locals => { :base_url => local_url("/users"), :refered => user, :current_board => board }
  end

  def get_timeline(ribbon_id, timeline_id, newest_score, oldest_score, count)
    timeline = Timeline.attach_if_exist(timeline_id) or raise
    if ribbon_id == 0
      raise if !timeline.independent?
    else
      ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
      ribbon.readable_by?(@user) or halt 403
    end
    JSONP(make_timeline_data(
        ribbon, timeline, newest_score, oldest_score, count))
  end

  def get_detail(ribbon_id, post_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.readable_by?(@user) or halt 403
    post = Post.attach_if_exist(post_id) or raise
    JSONP(make_detail_data(ribbon, post))
  end

  def get_group(group_id)
    group = Group.attach_if_exist(group_id) or raise
    JSONP(
      {
        :name => group.name,
        :nameEditable => group.name_editable,
        :members => 
        group.list_members.map do |user|
          {
            :userId => user.store.id,
            :username => user.store.username,
            :label => user.store.label,
            :gravatar => Misc.gravatar(user.store.email)
          }
        end
      })
  end

  def get_userlist
    JSONP(
      World.singleton.list_users.map do |user|
        [user.store.id, user.store.username, user.store.label, Misc.gravatar(user.store.email)]
      end)
  end

  def get_grouplist
    JSONP(
      Groups.singleton.list.map do |group|
        [group.store.id, group.store.name]
      end)
  end

  def get_memberlist(group_id)
    group = Group.attach_if_exist(group_id) or raise
    JSONP(
      group.list_members.map do |user|
        [user.store.id, user.store.username, user.store.label, Misc.gravatar(user.store.email)]
      end)
  end

  def get_boardlist(target_id)
    target = User.attach_if_exist(target_id) or raise
    JSONP(
      target.store.boards.select do |boardname, board|
        board.readable_by?(@user)
      end.map do |boardname, board|
        {
          :boardId => board.store.id,
          :label => board.store.label
        }
      end)
  end

  def get_ribbonlist(board_id)
    board = Board.attach_if_exist(board_id) or raise
    board.readable_by?(@user) or halt 403
    JSONP(
      board.list_ribbons.select do |ribbon|
        ribbon.readable_by?(@user)
      end.map do |ribbon|
        {
          :ribbonId => ribbon.store.id,
          :label => ribbon.label
        }
      end)
  end

  def get_removedribbonlist(board_id)
    board = Board.attach_if_exist(board_id) or raise
    board.readable_by?(@user) or halt 403
    JSONP(
      board.list_removed_ribbons.map do |ribbon|
        [ribbon.store.id, ribbon.label]
      end)
  end

  def post_new_article(ribbon_id, content)
    check_post_content(content)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.writable_by?(@user) or halt 403

    @user.add_article(ribbon, :Tweet, content).store.id.to_s
  end

  def post_new_comment(ribbon_id, parent_id, type, content)
    check_post_content(content)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.writable_by?(@user) or halt 403

    parent = Post.attach_if_exist(parent_id) or raise
    @user.add_comment(ribbon, parent, type, params[:content]).store.id.to_s
  end

  def move_article(ribbon_id, source_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.editable_by?(@user) or halt 403
    source = Post.attach_if_exist(source_id) or raise
    target = Post.attach_if_exist(target_id)

    @user.move_article(ribbon, source, target)
  end

  def transfer_article(source_ribbon_id, target_ribbon_id, source_id, target_id)
    source_ribbon = Ribbon.attach_if_exist(source_ribbon_id) or raise
    source_ribbon.editable_by?(@user) or halt 403
    target_ribbon = Ribbon.attach_if_exist(target_ribbon_id) or raise
    target_ribbon.editable_by?(@user) or halt 403
    source = Post.attach_if_exist(source_id) or raise
    target = Post.attach_if_exist(target_id)

    @user.transfer_article(source_ribbon, target_ribbon, source, target)
  end

  def favor(ribbon_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.writable_by?(@user) or halt 403
    post = Post.attach_if_exist(target_id) or raise
    @user.favor(ribbon, post)
  end

  def unfavor(ribbon_id, target_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.writable_by?(@user) or halt 403
    post = Post.attach_if_exist(target_id) or raise
    @user.unfavor(ribbon, post)
  end

  def make_new_board(label)
    board = @user.add_board(label)
    return_board(board)
  end

  def join_board(board_id)
    board = Board.attach_if_exist(board_id) or raise
    board.readable_by?(@user) or halt 403
    @user.join_board(board)
    return_board(board)
  end

  def make_new_ribbon(board_id, label)
    board = Board.attach_if_exist(board_id) or raise
    board.editable_by?(@user) or halt 403

    @user.add_ribbon(board, label)
    return JSONP(:version => board.version)
  end

  def join_ribbon(board_id, ribbon_id)
    board = Board.attach_if_exist(board_id) or raise
    board.editable_by?(@user) or halt 403

    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.readable_by?(@user) or halt 403
    @user.join_ribbon(board, ribbon)
    return JSONP(:version => board.version)
  end

  def restore_ribbon(board_id, ribbon_id)
    board = Board.attach_if_exist(board_id) or raise
    board.editable_by?(@user) or halt 403

    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.readable_by?(@user) or halt 403
    @user.restore_ribbon(board, ribbon)
    return JSONP(:version => board.version)
  end

  def close_ribbon(board_id, ribbon_id)
    board = Board.attach_if_exist(board_id) or raise
    board.editable_by?(@user) or halt 403

    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    @user.remove_ribbon(board, ribbon)
    return JSONP(:version => board.version)
  end

  def do_ribbon_test(ribbon_id)
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.do_test(@user)
    "OK"
  end

  def modify_board_settings(
      board_id,
      board_label,
      read_permission,
      write_permission,
      edit_permission,
      readable_group,
      writable_group,
      editable_group)
    board = Board.attach_if_exist(board_id) or raise
    board.editable_by?(@user) or halt 403

    @user.rename_board(board, board_label)

    readable_group = convert_permission_group(read_permission, readable_group)
    writable_group = convert_permission_group(write_permission, writable_group)
    editable_group = convert_permission_group(edit_permission, editable_group)

    board.modify_settings(
      @user,
      read_permission, readable_group,
      write_permission, writable_group,
      edit_permission, editable_group)

    return JSONP(:version => board.version)
  end

  def modify_ribbon_settings(
      board_id,
      ribbon_id,
      ribbon_label,
      read_permission,
      write_permission,
      edit_permission,
      readable_group,
      writable_group,
      editable_group)
    board = Board.attach_if_exist(board_id) or raise
    ribbon = Ribbon.attach_if_exist(ribbon_id) or raise
    ribbon.editable_by?(@user) or halt 403

    @user.rename_ribbon(ribbon, ribbon_label)

    readable_group = convert_permission_group(read_permission, readable_group)
    writable_group = convert_permission_group(write_permission, writable_group)
    editable_group = convert_permission_group(edit_permission, editable_group)

    board.modify_ribbon_settings(
      @user,
      ribbon,
      read_permission, readable_group,
      write_permission, writable_group,
      edit_permission, editable_group)

    return JSONP(:version => ribbon.owner.version)
  end

  def return_board(board)
    JSONP([board.owner.username, board.label])
  end

  def convert_permission_group(permission, group)
    case permission
    when :public_group
      return Group.attach_if_exist(group)
    when :private_group
      return group.map { |x| User.attach_if_exist(x) }      
    else
      return group
    end
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
      :ribbonId => ribbon ? ribbon.store.id : 0,
      :commentsId => comments ? comments.store.id : 0,
      :commentsLength => comments ? comments.length : 0,
      :commentsVersion => comments ? comments.version : 0,
      :authorLabel => author.label,
      :authorUsername => author.username,
      :favoredBy => post.store.favored_by.map { |x|
        {
          :label => x.label,
          :gravatar => Misc.gravatar(x.email)
        }
      },
      :userExists => (@user ? true : false),
      :postId => post.store.id,
      :favored => @user ? @user.favors?(post) : '',
      :content => content,
      :elapsed => (Time.now - post.created_at).to_i
    }
  end

  def make_timeline_data(ribbon, timeline, newest_score, oldest_score, count)
    # haxeのtemplateの仕様の都合でdetailと重複がある
    # TODO: haxe側で対処する
    posts, res_newest_score, res_oldest_score = timeline.fetch(
      newest_score, oldest_score, count)
    {
      :ribbonId => ribbon ? ribbon.store.id : 0,
      :timelineId => timeline.store.id,
      :timelineVersion => timeline.store.version,
      :newestScore => res_newest_score,
      :oldestScore => res_oldest_score,
      :posts => posts.map do |score, removed, post|
        detail = make_detail_data(ribbon, post)
        {
          :score => score,
          :removed => removed,
          :postId => post.store.id,
          :postType => post.type,
          :postVersion => post.store.version,
          :icon => Misc.gravatar(post.store.author.store.email),
          :detail => detail,
          :commentsId => detail[:commentsId],
          :commentsLength => detail[:commentsLength],
          :commentsVersion => detail[:commentsVersion],
          :comments => [],
          :userExists => @user ? true : false,
          :editable => ribbon ? ribbon.editable_by?(@user) : false,
          :chatIconUrl => local_url('/images/chat.png')
        }
      end,
    }
  end

  def check_post_content(content)
    raise if content =~ /^\s*$/
  end

end

