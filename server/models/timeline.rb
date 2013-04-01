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
    # [newest_score, oldest_score)の範囲を返す
    # newest_score, oldest_scoreがnilの場合無限を指す
    
    b = newest_score.kick(nil, :inf)
    e = oldest_score.kick(nil, :'-inf')

    posts = self.store.posts
    a = posts.revrange(b, e, [0, count + 1])
    if a.empty?
      [[], nil, nil]
    else
      res_newest_score = a.first[:score]
      res_oldest_score = a.last[:score]
      if a.length <= count
        # 続きがない
        res_oldest_score = oldest_score || 0
      else
        # oldestはexclusive
        a.pop
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
    if self.store.posts.last_value != post
      self.store.posts.add(version_up, post)
    end
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
