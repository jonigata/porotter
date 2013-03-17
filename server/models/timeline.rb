class Timeline < RedisMapper::PlatformModel
  def self.create
    self.new_instance
  end

  def add_post(post)
    self.store.posts.add(post.store.created_at.to_i, post)
  end

  def remove_post(post)
    self.store.posts.remove(post)
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

  ordered_set_property  :posts, Post
end
