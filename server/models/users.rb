class Users < RedisMapper::PlatformModel
  def self.singleton
    self.attach(1)
  end

  def add_user(user)
    self.store.users.add(user)
  end

  set_property :users, User
end
