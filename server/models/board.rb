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

  delegate :add_ribbon, :add        do self.store.ribbons end
  delegate :remove_ribbon, :remove  do self.store.ribbons end
  delegate :list_ribbons, :to_a     do self.store.ribbons end

  delegate :secret?                 do self.store.spotter end
  delegate :editable_by?            do self.store.spotter end

  property      :owner,     User
  property      :label,     String
  property      :spotter,   Spotter
  list_property :ribbons,   Ribbon
end
