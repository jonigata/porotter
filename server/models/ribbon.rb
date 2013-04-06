# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel; end

class Ribbon < RedisMapper::PlatformModel
  def self.create(owner, read_source, write_target)
    self.new_instance.tap do |ribbon|
      ribbon.store.read_source = read_source
      ribbon.store.write_target = write_target
    end
  end

  def add_article(post)
    timeline = self.store.write_target
    return nil unless timeline
    timeline.add_post(post)
    post
  end

  def add_comment(parent, post)
    parent.add_comment(post)
    post
  end

  delegate :read_source     do self.store end
  delegate :write_target    do self.store end

  property  :owner,         Board
  property  :read_source,   Timeline
  property  :write_target,  Timeline
end
