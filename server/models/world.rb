# -*- coding: utf-8 -*-

class World < RedisMapper::PlatformModel
  include RedisMapper::Singleton;

  def self.on_create(world)
    global_group = Group.create
    global_timeline = Timeline.create(nil, '井戸端会議')
    global_user = User.create_global('ruin837e', global_timeline)

    world.store.global_group = global_group
    world.store.global_timeline = global_timeline
    world.store.global_user = global_user
  end

  def add_user(user)
    self.store.global_group.add_member(user)
  end

  def list_users
    self.store.global_group.list_members
  end

  property      :global_group,      Group
  property      :global_timeline,   Timeline
  property      :global_user,       User
end
