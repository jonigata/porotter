# -*- coding: utf-8 -*-

class Spotter < RedisMapper::PlatformModel
  def self.create(read_permission, write_permission)
    self.new_instance.tap do |spotter|
      spotter.store.read_permission = read_permission
      spotter.store.write_permission = write_permission
      # TODO: membersのcreate
    end
  end

  def add_member(member)
    self.store.members.add(member)
  end

  def clone
    self.class.new_instance.tap do |it|
      it.read_permission = self.store.read_permission
      it.write_permission = self.store.write_permission
      # TODO: membersのclone
    end
  end

  def secret?
    self.store.read_permission != :public
  end

  property  :read_permission,   Symbol      # :public, :closed, :private
  property  :write_permission,  Symbol
  property  :members,           Group
end
