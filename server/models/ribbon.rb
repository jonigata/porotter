# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel; end

class Ribbon < RedisMapper::PlatformModel
  def self.create(
      owner,
      read_source,
      write_target,
      read_spotter,
      write_spotter,
      edit_spotter)
    self.new_instance.tap do |ribbon|
      ribbon.store.owner = owner
      ribbon.store.read_spotter = read_spotter
      ribbon.store.write_spotter = write_spotter
      ribbon.store.edit_spotter = edit_spotter
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

  def secret?
    return self.store.read_spotter.secret?
  end

  def readable_by?(user)
    return self.store.read_spotter.permitted?(user)
  end

  def writable_by?(user)
    return false unless write_target
    return self.store.write_spotter.permitted?(user)
  end

  def editable_by?(user)
    return false unless write_target
    return self.store.edit_spotter.permitted?(user)
  end

  def label
    self.store.read_source.store.label
  end

  def do_test(author)
    add_article(p1 = Post.create(author, :Tweet, '1', true))
    add_article(p2 = Post.create(author, :Tweet, '2', true))
    add_article(p3 = Post.create(author, :Tweet, '3', true))
    self.store.write_target.remove_post(p3)
    add_article(p3)
  end

  delegate :read_source     do self.store end
  delegate :write_target    do self.store end

  property  :owner,         Board
  property  :read_spotter,  Spotter
  property  :write_spotter, Spotter
  property  :edit_spotter,  Spotter
  property  :read_source,   Timeline
  property  :write_target,  Timeline
end
