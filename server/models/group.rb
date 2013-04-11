# -*- coding: utf-8 -*-

class Group < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |group|
    end
  end

  def add_member(member)
    self.store.members.add(member)
  end

  set_property  :members,   User
end
