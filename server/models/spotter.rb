# -*- coding: utf-8 -*-

class Spotter < RedisMapper::PlatformModel
  def self.create(read_permission, write_permission)
    self.new_instance.tap do |spotter|
      spotter.store.read_permission = read_permission
      spotter.store.write_permission = write_permission
    end
  end

  def add_member(member)
    self.store.members.add(member)
  end

  property  :read_permission,   Symbol      # :public, :closed, :private
  property  :write_permission,  Symbol
  property  :members,       Group
end
