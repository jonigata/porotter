class Timeline < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |timeline|
      timeline.store.version = 1
    end
  end

  def add_post(post)
    self.store.posts.add(post.store.created_at.to_i, post)
    version = self.store.version_incr(1)
    redis.publish "timeline-watcher", [self.store.id, version].to_json
  end

  def remove_post(post)
    self.store.posts.remove(post)
    version = self.store.version_incr(1)
    redis.publish "timeline-watcher", [self.store.id, version].to_json
  end

  def member?(post)
    self.store.posts.member?(post)
  end

  def fetch_all(direction)
    if direction == :upward
      self.store.posts.range_by_revrank(0, -1)
    else
      self.store.posts.range_by_rank(0, -1)
    end
  end

  def length
    self.store.posts.length
  end

  def empty?
    self.store.posts.empty?
  end

  property              :version, Integer
  ordered_set_property  :posts, Post
end
