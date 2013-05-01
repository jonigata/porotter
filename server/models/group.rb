# -*- coding: utf-8 -*-

class Group < RedisMapper::PlatformModel
  def self.create(name, name_editable)
    self.new_instance.tap do |group|
      group.store.name = name
      group.store.name_editable = name_editable
    end
  end

  def add_member(member)
    self.store.members.add(member)
  end

  def member?(member)
    self.store.members.member?(member)
  end

  def empty?
    self.store.members.empty?
  end

  def set(a)
    members = self.store.members
    members.clear
    a.each do |k|
      members.add(k)
    end
  end

  delegate :name do self.store end
  delegate :name_editable do self.store end
  delegate :list_members, :to_a do self.store.members end

  property      :name,          String
  property      :name_editable, Boolean
  set_property  :members,       User
end
