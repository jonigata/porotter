class Timeline < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |timeline|
      timeline.store.version = 1
    end
  end

  def add_post(post)
    self.store.posts.add(version_up, post)
  end

  def remove_post(post)
    version_up
    self.store.posts.remove(post)
  end

  def member?(post)
    self.store.posts.member?(post)
  end

  def fetch_all(direction)
    if direction == :upward
      self.store.posts.revrange(:inf, :'-inf', [0, 5]).map do |h|
        h[:value]
      end
    else
      self.store.posts.range(:'-inf', :inf,  [0, 5]).map do |h|
        h[:value]
      end
    end
  end

  def length
    self.store.posts.length
  end

  def empty?
    self.store.posts.empty?
  end

  private
  def version_up
    self.store.version_incr(1).tap do |version|
      redis.publish "timeline-watcher", [self.store.id, version].to_json
    end
  end    

  property              :version,   Integer
  ordered_set_property  :posts,     Post
end
