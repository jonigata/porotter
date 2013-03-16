class SignUpError < Exception; end

RedisMapper::PlatformModel.set_redis(Redis.new)

class User < RedisMapper::PlatformModel
  def self.create(username, password)
    begin
      raise "Username must be at least 3 characters" if username.length < 3
      raise "Password must be at least 4 characters!" if password.length < 4
      raise "Username must only contain letters, numbers and underscores." if
        username !~ /^\w+$/
      raise "That username is taken." if username == 'all'
      raise "That username is taken." unless
        redis.setnx("user:username:#{username}", 0)

      self.new_instance do |user|
        user.store.username = username
        user.store.password = password
      end
    rescue => e
      raise SignUpError, e
    end
  end

  property :username,   String
  property :password,   String
end
