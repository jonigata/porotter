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
    self.store.removed_ribbons.push(ribbon)
    self.store.ribbons.remove(ribbon)
  end

  def restore_ribbon(ribbon)
    puts "************restore***********"
    self.store.ribbons.push(ribbon)
    self.store.removed_ribbons.remove(ribbon)
  end

  delegate :add_ribbon, :push       do self.store.ribbons end
  delegate :list_ribbons, :to_a     do self.store.ribbons end
  delegate :list_removed_ribbons, :to_a do self.store.removed_ribbons end

  delegate :secret?                 do self.store.spotter end
  delegate :editable_by?            do self.store.spotter end

  property      :owner,             User
  property      :label,             String
  property      :spotter,           Spotter
  list_property :ribbons,           Ribbon
  list_property :removed_ribbons,   Ribbon
end
