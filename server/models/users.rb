class Users < RedisMapper::PlatformModel
  include RedisMapper::Singleton;

  def add_user(user)
    self.store.users.add(user)
  end

  set_property  :users, User
  property      :global_timeline, Timeline
end
