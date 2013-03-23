class Post < RedisMapper::PlatformModel
  def self.create(user, content)
    self.new_instance do |post|
      post.store.version = 1
      post.store.author = user
      post.store.content = content
      post.store.created_at = post.store.updated_at = Time.now
      post.store.comments = Timeline.create
    end
  end

  def add_comment(author, content)
    self.store.comments.add_post(Post.create(author, content))
    self.store.version_incr(1)
  end

  def favor
    post.store.favored_incr(1)
    version_up
  end

  def unfavor
    post.store.favored_incr(-1)
    post.store.version_incr(1)
    version_up
  end

  private
  def version_up
    version = post.store.version_incr(1)
    redis.publish "post-watcher", [:post, post.store.id, version].to_json
  end

  property  :version,       Integer
  property  :author,        User
  property  :content,       String
  property  :created_at,    Time
  property  :updated_at,    Time
  property  :comments,      Timeline
  property  :favored,       Integer
end
