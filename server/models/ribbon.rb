# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel; end

class Ribbon < RedisMapper::PlatformModel
  def self.create(owner, read_source, write_target)
    self.new_instance.tap do |ribbon|
      ribbon.read_source = read_source
      ribbon.write_target = write_target
    end
  end

  def add_article(post)
    timeline = self.store.write_target
    return nil unless timeline
    timeline.add_post(post)
    post
  end

  def add_comment(parent, post)
    timeline = self.store.write_target
    return nil unless timeline
    parent.add_comment(post)
    post
  end

  property  :owner,         Board
  property  :read_source,   Timeline
  property  :write_target,  Timeline
end
