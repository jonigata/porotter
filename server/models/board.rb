# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  def self.create(owner, label)
    self.new_instance.tap do |board|
      board.store.owner = owner
      board.store.label = label
      board.store.read_spotter = Spotter.create(:read, [owner])
      board.store.write_spotter = Spotter.create(:write, [owner])
      board.store.edit_spotter = Spotter.create(:edit, [owner])
    end
  end

  def import(read, write)
    Ribbon.create(
      self,
      read,
      write,
      self.store.read_spotter,
      self.store.write_spotter,
      self.store.edit_spotter).tap do |ribbon|
      self.store.ribbons.push(ribbon)
    end
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
    format_permission(self.store.read_spotter)
  end

  def format_writability
    format_permission(self.store.write_spotter)
  end

  def secret?
    return self.store.read_spotter.secret?
  end

  def readable_by?(user)
    return self.store.read_spotter.permitted?(user)
  end

  def writable_by?(user)
    return self.store.write_spotter.permitted?(user)
  end

  def editable_by?(user)
    return self.store.edit_spotter.permitted?(user)
  end

  private
  def format_permission(spotter)
    {
      :everyone => false,
      :public_group => false,
      :private_group => false,
      :same_as_read => false,
      :same_as_write => false,
    }.tap do |result|
      permission = spotter.store.permission
      case permission
      when :everyone
        result[:everyone] = true
      when :outsource
        if spotter.store.source == self.store.read_spotter
          result[:same_as_read] = true
        elsif spotter.store.source == self.store.write_spotter
          result[:same_as_write] = true
        end
      when :group
        result[spotter.unique? ? :private_group : :public_group] = true
      end
    end
  end

  delegate :add_ribbon, :push       do self.store.ribbons end
  delegate :list_ribbons, :to_a     do self.store.ribbons end
  delegate :list_removed_ribbons, :to_a do self.store.removed_ribbons end

  delegate :readble_by?, :permitted?    do self.store.read_spotter end
  delegate :writable_by?, :permitted?   do self.store.write_spotter end
  delegate :editable_by?, :permitted?   do self.store.edit_spotter end

  property      :owner,             User
  property      :label,             String
  property      :read_spotter,      Spotter
  property      :write_spotter,     Spotter
  property      :edit_spotter,      Spotter
  list_property :ribbons,           Ribbon
  list_property :removed_ribbons,   Ribbon
end
