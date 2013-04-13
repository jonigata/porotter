# -*- coding: utf-8 -*-

class Users < RedisMapper::PlatformModel
  include RedisMapper::Singleton;

  def self.on_create(users)
    users.store.global_timeline = Timeline.create(nil, '井戸端会議')
  end

  def add_user(user)
    self.store.users.add(user)
  end

  def list
    self.store.users.to_a
  end

  set_property  :users, User
  property      :global_timeline, Timeline
end
