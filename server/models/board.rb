# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  def self.create(owner, label)
    self.new_instance.tap do |board|
      board.store.owner = owner
      board.store.label = label
      board.store.unique_readable = unique_readable = Group.create
      board.store.unique_writable = unique_writable = Group.create
      unique_readable.add_member(owner)
      unique_writable.add_member(owner)
      board.store.spotter = Spotter.create(unique_readable, unique_writable)
    end
  end

  def import(read_source, write_target)
    self.store.ribbons.push(
      Ribbon.create(self, read_source, write_target, self.store.spotter))
  end

  def remove_ribbon(ribbon)
    self.store.removed_ribbons.push(ribbon)
    self.store.ribbons.remove(ribbon)
  end

  def restore_ribbon(ribbon)
    self.store.ribbons.push(ribbon)
    self.store.removed_ribbons.remove(ribbon)
  end

  def format_readability
    result = [false, false, false]
    spotter = self.store.spotter
    rt = spotter.store.readable_type
    if rt == :everyone
      result[0] = true
    else
      rg = spotter.store.readable_group
      if self.store.unique_readable == rg
        result[2] = true
      else
        result[1] = true
      end
    end
    result
  end

  def format_writability
    result = [false, false, false, false]
    spotter = self.store.spotter
    wt = spotter.store.writable_type
    if wt == :everyone
      result[0] = true
    elsif wt == :same_as_readable
      result[3] = true
    else
      wg = spotter.store.writable_group
      if self.store.unique_writable == wg
        result[2] = true
      else
        result[1] = true
      end
    end
    result
  end

  delegate :add_ribbon, :push       do self.store.ribbons end
  delegate :list_ribbons, :to_a     do self.store.ribbons end
  delegate :list_removed_ribbons, :to_a do self.store.removed_ribbons end

  delegate :set_readability         do self.store.spotter end
  delegate :set_writability         do self.store.spotter end
  delegate :secret?                 do self.store.spotter end
  delegate :editable_by?            do self.store.spotter end

  property      :owner,             User
  property      :label,             String
  property      :spotter,           Spotter
  property      :unique_readable,   Group
  property      :unique_writable,   Group
  list_property :ribbons,           Ribbon
  list_property :removed_ribbons,   Ribbon
end
