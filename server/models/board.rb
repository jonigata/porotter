# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  def self.create(owner, name, label, read_permission, write_permission)
    self.new_instance.tap do |board|
      board.store.owner = owner
      board.store.name = name
      board.store.label = label
      board.store.spotter = Spotter.create(read_permission, write_permission)
    end
  end

  def import(read_source, write_target)
    self.store.ribbons.push(
      Ribbon.create(self, read_source, write_target, self.store.spotter))
  end

  def remove_ribbon(ribbon)
    ribbons.remove(ribbon)
  end

  delegate :add_ribbon, :add        do self.store.ribbons end
  delegate :remove_ribbon, :remove  do self.store.ribbons end
  delegate :list_ribbons, :to_a     do self.store.ribbons end

  property      :owner,     User
  property      :name,      String
  property      :label,     String
  property      :spotter,   Spotter
  list_property :ribbons,   Ribbon
end
