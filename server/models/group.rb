# -*- coding: utf-8 -*-

class Group < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |group|
    end
  end

  def add_member(member)
    self.store.members.add(member)
  end

  def member?(member)
    self.store.members.member?(member)
  end

  delegate :list_members, :to_a do self.store.members end

  set_property  :members,   User
end
