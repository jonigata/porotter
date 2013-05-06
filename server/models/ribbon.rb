# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel; end

class Ribbon < RedisMapper::PlatformModel
  include SpotterHolder

  def self.create(
      owner,
      label,
      timeline,
      read_spotter,
      write_spotter,
      edit_spotter)
    self.new_instance.tap do |ribbon|
      ribbon.store.owner = owner
      ribbon.store.label = label
      ribbon.store.timeline = timeline
      ribbon.store.read_spotter = Spotter.create(:read, read_spotter)
      ribbon.store.write_spotter = Spotter.create(:write, write_spotter)
      ribbon.store.edit_spotter = Spotter.create(:edit, edit_spotter)
    end
  end

  def add_article(post)
    timeline = self.store.timeline
    return nil unless timeline
    timeline.add_post(post)
    post
  end

  def add_comment(parent, post)
    parent.add_comment(post)
    post
  end

  def do_test(author)
    add_article(p1 = Post.create(author, :Tweet, '1', true))
    add_article(p2 = Post.create(author, :Tweet, '2', true))
    add_article(p3 = Post.create(author, :Tweet, '3', true))
    self.store.timeline.remove_post(p3)
    add_article(p3)
  end

  def parent_spotter(type)
    self.store.owner.__send__("#{type}_spotter".intern)
  end

  def rename(label)
    self.store.label = label
  end

  def writable_by?(user)
    write_spotter.permitted?(user)
  end

  delegate :label           do self.store end
  delegate :owner           do self.store end
  delegate :timeline        do self.store end
  delegate :read_spotter    do self.store end
  delegate :write_spotter   do self.store end
  delegate :edit_spotter    do self.store end

  property  :owner,         Board
  property  :label,         String
  property  :timeline,      Timeline
  property  :read_spotter,  Spotter
  property  :write_spotter, Spotter
  property  :edit_spotter,  Spotter
end
