# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  def self.create(owner, label, read_permission, write_permission)
    self.new_instance.tap do |board|
      board.store.owner = owner
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

  def secret?
    spotter = self.store.spotter or return false
    spotter.secret?
  end

  delegate :add_ribbon, :add        do self.store.ribbons end
  delegate :remove_ribbon, :remove  do self.store.ribbons end
  delegate :list_ribbons, :to_a     do self.store.ribbons end

  property      :owner,     User
  property      :label,     String
  property      :spotter,   Spotter
  list_property :ribbons,   Ribbon
end
