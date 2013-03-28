# -*- coding: utf-8 -*-
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

  def fetch_all(newest_version, count)
    if newest_version
      newest_version -= 1
    else
      newest_version = :inf
    end

    posts = self.store.posts
    a = posts.revrange(newest_version, 0, [0, count])
    if a.empty?
      [[], 0]
    else
      last_score = a.last[:score]
      rest = posts.length_range(0, last_score-1)
      puts "rest == #{rest}"
      last_score = 0 if rest == 0 # 続きがない
      [a.map { |h| h[:value] }, last_score]
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
