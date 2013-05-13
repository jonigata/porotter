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
      ribbon.store.referers.add(owner)
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
    broadcast_activity("#{post.author.username}の新規投稿: #{post.content}")
    post
  end

  def add_comment(parent, post)
    parent.add_comment(post)
    broadcast_activity("#{post.author.username}のコメント: #{post.content}")
    post
  end

  def move_article(user, source, target)
    self.timeline.move_post(source, target)    
    self.add_comment(
      source, Post.create(user, :ArticleLog, "移動: タイムライン内", false))
    broadcast_activity("#{post.author.username}が投稿を移動")
  end

  def transfer_article(user, source_ribbon, source, target)
    self.timeline.transfer_post_from(source_ribbon.timeline, source, target)    

    message = Sanitize.clean("移動: #{source_ribbon.label} → #{self.label}")
    self.add_comment(source, Post.create(user, :ArticleLog, message, false))
    broadcast_activity("#{user.username}が投稿を移動")
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

  def broadcast_activity(text)
    self.store.referers.each do |referer|
      referer.add_activity(text)
    end
  end

  def do_test(author)
    add_article(p1 = Post.create(author, :Tweet, '1', true))
    add_article(p2 = Post.create(author, :Tweet, '2', true))
    add_article(p3 = Post.create(author, :Tweet, '3', true))
    self.store.timeline.remove_post(p3)
    add_article(p3)
  end

  delegate :label           do self.store end
  delegate :owner           do self.store end
  delegate :timeline        do self.store end
  delegate :read_spotter    do self.store end
  delegate :write_spotter   do self.store end
  delegate :edit_spotter    do self.store end
  delegate :add_referer,    :add    do self.store.referers end
  delegate :remove_referer, :remove do self.store.referers end

  property  :owner,         Board
  property  :label,         String
  property  :timeline,      Timeline
  property  :read_spotter,  Spotter
  property  :write_spotter, Spotter
  property  :edit_spotter,  Spotter
  set_property  :referers,  Board
end
