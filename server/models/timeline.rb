# -*- coding: utf-8 -*-

class Timeline < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |timeline|
      timeline.store.version = 1
    end
  end

  def add_post(post)
    self.store.posts.add(version_up, post)
    post.watched_by(self)
  end

  def remove_post(post)
    version_up
    self.store.posts.remove(post)
  end

  def member?(post)
    self.store.posts.member?(post)
  end

  def fetch(newest_score, oldest_score, count)
    b = newest_score ? newest_score - 1 : :inf
    e = oldest_score ? oldest_score + 1 : :'-inf'

    posts = self.store.posts
    a = posts.revrange(b, e, [0, count])
    if a.empty?
      [[], nil, nil]
    else
      res_newest_score = a.first[:score]
      res_oldest_score = a.last[:score]
      if posts.length_range(0, res_oldest_score - 1) == 0
        # 続きがない
        res_oldest_score = 0
      end
      [a, res_newest_score, res_oldest_score]
    end
  end

  def length
    self.store.posts.length
  end

  def empty?
    self.store.posts.empty?
  end

  def on_add_comment(post)
    # bump up
    self.store.posts.add(version_up, post)
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
