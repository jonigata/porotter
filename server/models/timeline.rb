class Timeline < RedisMapper::PlatformModel
  def self.create
    self.new_instance
  end

  def add_post(post)
    self.store.posts.add(post.store.created_at.to_i, post)
  end

  def fetch_all
    self.store.posts.range_by_revrank(0, -1)
  end

  ordered_set_property  :posts, Post
end
