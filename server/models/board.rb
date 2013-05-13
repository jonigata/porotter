# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  include SpotterHolder

  def self.create(owner, label)
    self.new_instance.tap do |board|
      board.store.owner = owner
      board.store.label = label
      board.store.read_spotter = Spotter.create(:read, [owner])
      board.store.write_spotter = Spotter.create(:write, [owner])
      board.store.edit_spotter = Spotter.create(:edit, [owner])
      board.store.activity = Timeline.create(owner)
    end
  end

  def import_ribbon(ribbon)
    import_ribbon_aux(ribbon)
  end

  def make_ribbon(label)
    timeline = Timeline.create(self.owner)
    make_ribbon_aux(label, timeline)
  end

  def make_readonly_ribbon(label)
    timeline = Timeline.create(self.owner)
    make_ribbon_aux(label, timeline).tap do |ribbon|
      ribbon.write_spotter.set_permission([])
      ribbon.edit_spotter.set_permission([])
    end
  end

  def set_label(label)
    self.store.label = label
  end

  def remove_ribbon(ribbon)
    self.store.removed_ribbons.push(ribbon)
    self.store.ribbons.remove(ribbon)
  end

  def restore_ribbon(ribbon)
    self.store.ribbons.push(ribbon)
    self.store.removed_ribbons.remove(ribbon)
  end

  def rename_ribbon(ribbon, label)
    ribbon.rename(label)
  end

  def parent_spotter
    raise
  end

  def first_ribbon
    return self.store.ribbons.first
  end

  def add_activity(content)
    Post.create(self, :ArticleLog, content, false).tap do |post|
      puts "*** activity: #{content.inspect}"
      self.store.activity.add_post(post)
    end
  end

  private
  def make_ribbon_aux(label, timeline)
    Ribbon.create(
      self,
      label,
      timeline,
      self.store.read_spotter,
      self.store.write_spotter,
      self.store.edit_spotter).tap do |ribbon|
      import_ribbon_aux(ribbon)
    end
  end

  def import_ribbon_aux(ribbon)
    self.store.ribbons.push(ribbon)
    ribbon.add_referer(self)
  end

  delegate :owner                       do self.store end
  delegate :label                       do self.store end
  delegate :add_ribbon, :push           do self.store.ribbons end
  delegate :list_ribbons, :to_a         do self.store.ribbons end
  delegate :list_removed_ribbons, :to_a do self.store.removed_ribbons end

  property      :owner,             User
  property      :label,             String
  property      :read_spotter,      Spotter
  property      :write_spotter,     Spotter
  property      :edit_spotter,      Spotter
  list_property :ribbons,           Ribbon
  list_property :removed_ribbons,   Ribbon
  property      :activity,          Timeline
end
