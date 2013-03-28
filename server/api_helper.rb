# -*- coding: utf-8 -*-

module APIHelper
  def get_timeline(timeline_id, newest_version, count)
    timeline = Timeline.attach_if_exist(timeline_id) or raise
    JSONP(make_timeline_data(timeline, newest_version, count))
  end

  def get_detail(post_id)
    post = Post.attach_if_exist(post_id) or raise
    JSONP(make_detail_data(post))
  end

  def post_new_article(content)
    @user.add_article(content).store.id.to_s
  end

  def post_new_comment(parent_id, content)
    parent = Post.attach_if_exist(parent_id) or raise
    @user.add_comment(parent, params[:content]).store.id.to_s
  end

  def favor(target_id)
    post = Post.attach_if_exist(target_id) or raise
    @user.toggle_favorite(post)
  end

  private
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

  def make_timeline_data(timeline, newest_version, count)
    posts, last_score = timeline.fetch_all(newest_version.kick(0), count)
    {
      :timelineId => timeline.store.id,
      :timelineVersion => timeline.store.version,
      :lastScore => last_score,
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

