# -*- coding: utf-8 -*-

class Groups < RedisMapper::PlatformModel
  include RedisMapper::Singleton;

  def self.on_create(groups)
  end

  def add_group(group)
    self.store.groups.add(group)
  end

  def list
    self.store.groups.to_a
  end

  set_property  :groups,    Group
end
