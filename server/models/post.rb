# -*- coding: utf-8 -*-

class Post < RedisMapper::PlatformModel
  def self.create(author, type, content, has_comments)
    self.new_instance do |post|
      post.store.type = type
      post.store.version = 1
      post.store.author = author
      post.store.content = content
      post.store.created_at = post.store.updated_at = Time.now
      post.store.comments =
        has_comments ? Timeline.create(author) : nil
    end
  end

  def add_comment(post)
    version_up do |version|
      self.store.comments.add_post(post)
      self.store.refered_by.each do |timeline|
        timeline.on_post_modified(self)
      end
    end
  end

  def favored_by(user)
    version_up do |version|
      self.store.favored_by.add(user)
    end
  end

  def unfavored_by(user)
    version_up do |version|
      self.store.favored_by.remove(user)
    end
  end

  def refered_by(timeline)
    self.store.refered_by.add(timeline)
  end

  delegate :created_at      do self.store end

  private
  def version_up
    self.store.version_incr(1).tap do |version|
      yield version
      redis.publish "post-watcher", [self.store.id, version].to_json
    end
  end

  delegate :type do self.store end

  property  :type,          Symbol
  property  :version,       Integer
  property  :author,        User
  property  :content,       String
  property  :created_at,    Time
  property  :updated_at,    Time
  property  :comments,      Timeline
  set_property :favored_by, User
  set_property :refered_by, Timeline
end
