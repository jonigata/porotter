# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  include SpotterHolder

  def self.create(owner, label)
    self.new_instance.tap do |board|
      board.store.owner = owner
      board.store.label = label
      board.store.version = 1
      board.store.read_spotter = Spotter.create(:read, [owner])
      board.store.write_spotter = Spotter.create(:write, [owner])
      board.store.edit_spotter = Spotter.create(:edit, [owner])
      board.store.activity = Timeline.create(owner, true)
    end
  end

  def import_ribbon(user, ribbon)
    import_ribbon_aux(ribbon)
    add_activity(user, "リボンのインポート: #{ribbon.label}")
  end

  def make_ribbon(user, label)
    timeline = Timeline.create(self.owner, false)
    make_ribbon_aux(label, timeline).tap do
      add_activity(user, "リボンの作成: #{label}")
    end
  end

  def make_readonly_ribbon(user, label)
    timeline = Timeline.create(self.owner, false)
    make_ribbon_aux(label, timeline).tap do |ribbon|
      ribbon.write_spotter.set_permission([])
      ribbon.edit_spotter.set_permission([])
      add_activity(user, "閲覧リボンの作成: #{label}")
    end
  end

  def set_label(label)
    version_up do |version|
      self.store.label = label
    end
  end

  def remove_ribbon(user, ribbon)
    version_up do |version|
      self.store.removed_ribbons.push(ribbon)
      self.store.ribbons.remove(ribbon)
      add_activity(user, "リボンの削除: #{ribbon.label}")
    end
  end

  def restore_ribbon(user, ribbon)
    version_up do |version|
      self.store.ribbons.push(ribbon)
      self.store.removed_ribbons.remove(ribbon)
      add_activity(user, "リボンの復活: #{ribbon.label}")
    end
  end

  def parent_spotter
    raise
  end

  def first_ribbon
    return self.store.ribbons.first
  end

  def add_activity(user, content)
    Post.create(user, :ArticleLog, content, false).tap do |post|
      puts "*** activity: \"#{content}\""
      self.store.activity.add_post(post)
    end
  end

  def add_observer(user)
    # TODO:
    #  古いのを消す
    #  数を制限する
    return unless user
    self.store.observers.add(Time.now.to_i, user)
    publish_observers
  end

  def remove_observer(user)
    return unless user
    self.store.observers.remove(user)
    publish_observers
  end

  def modify_settings(
      user,
      read_permission, readable_group,
      write_permission, writable_group,
      edit_permission, editable_group)
    version_up do |version|
      self.set_readability(read_permission, readable_group)
      self.set_writability(write_permission, writable_group)
      self.set_editability(edit_permission, editable_group)
      add_activity(user, "ボード設定変更")
    end
  end

  def modify_ribbon_settings(
      user,
      ribbon,
      read_permission, readable_group,
      write_permission, writable_group,
      edit_permission, editable_group)
    version_up do |version|
      ribbon.set_readability(read_permission, readable_group)
      ribbon.set_writability(write_permission, writable_group)
      ribbon.set_editability(edit_permission, editable_group)
      add_activity(user, "リボン設定変更: #{ribbon.label}")
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
    version_up do |version|
      self.store.ribbons.push(ribbon)
      ribbon.add_referer(self)
    end
  end

  def publish_observers
    a = self.store.observers.revrange(Time.now.to_i, Time.now.to_i - 60 * 60 * 24).map do |x|
      user = x[:value]
      {
        :userId => user.store.id,
        :label => user.label,
        :gravatar => user.gravatar
      }
    end
    redis.publish(
      "watch-observers",
      [self.store.id, a].to_json)
  end

  def version_up
    self.store.version_incr(1).tap do |version|
      yield version
      redis.publish "watch-board", [self.store.id, version].to_json
    end
  end

  delegate :owner                       do self.store end
  delegate :label                       do self.store end
  delegate :version                     do self.store end
  delegate :add_ribbon, :push           do self.store.ribbons end
  delegate :list_ribbons, :to_a         do self.store.ribbons end
  delegate :list_removed_ribbons, :to_a do self.store.removed_ribbons end

  property      :owner,             User
  property      :label,             String
  property      :version,           Integer
  property      :read_spotter,      Spotter
  property      :write_spotter,     Spotter
  property      :edit_spotter,      Spotter
  list_property :ribbons,           Ribbon
  list_property :removed_ribbons,   Ribbon
  property      :activity,          Timeline
  ordered_set_property  :observers, User # { unix-time => user }
end
