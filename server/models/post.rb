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
    version_up
    Post.create(author, content).tap do |post|
      self.store.comments.add_post(post)
    end
    self.store.watched_by.each do |timeline|
      timeline.on_add_comment(self)
    end
  end

  def favor(user)
    version_up
    self.store.favored_by.add(user)
  end

  def unfavor(user)
    version_up
    self.store.favored_by.remove(user)
  end

  def watched_by(timeline)
    self.store.watched_by.add(timeline)
  end

  private
  def version_up
    self.store.version_incr(1).tap do |version|
      redis.publish "post-watcher", [self.store.id, version].to_json
    end
  end

  property  :version,       Integer
  property  :author,        User
  property  :content,       String
  property  :created_at,    Time
  property  :updated_at,    Time
  property  :comments,      Timeline
  set_property :favored_by, User
  set_property :watched_by, Timeline
end
