class Users < RedisMapper::PlatformModel
  def self.singleton
    self.attach(1).tap do |users|
      users.store.global_timeline ||= Timeline.create
    end
  end

  def add_user(user)
    self.store.users.add(user)
  end

  set_property  :users, User
  property      :global_timeline, Timeline
end
