# -*- coding: utf-8 -*-
class SignUpError < Exception; end

RedisMapper::PlatformModel.set_redis(Redis.new)

class Timeline < RedisMapper::PlatformModel; end

class User < RedisMapper::PlatformModel
  def self.create(username, password)
    begin
      raise "Username must be at least 3 characters" if username.length < 3
      raise "Password must be at least 4 characters!" if password.length < 4
      raise "Username must only contain letters, numbers and underscores." if
        username !~ /^\w+$/
      raise "That username is taken." if username == 'all'

      self.make_index(:username, username) do 
        self.new_instance do |user|
          user.store.username = username
          salt = Misc.new_salt
          user.store.salt = salt
          user.store.hashed_password = Misc.hash_pw(salt, password)

          user.store.my_posts = Timeline.create
          user.store.primary_timeline = Timeline.create
          user.store.watchers.add(user.store.my_posts)
          user.store.watchers.add(user.store.primary_timeline)
          user.add_post("最初の投稿です")

          Users.singleton.add_user(user)
        end
      end or raise "That username is taken."
    rescue => e
      raise SignUpError, e
    end
  end

  def self.auth(username, password)
    self.store_class.find_by_username(username).tap do |user|
      user && user.auth(username, password) or return nil
    end
  end

  def auth(username, password)
    self.store.hashed_password == Misc.hash_pw(self.store.salt, password)
  end

  def add_post(content)
    Post.create(self, content).tap do |post|
      self.store.watchers.each do |tl|
        tl.add_post(post)
      end
    end
  end

  def add_comment(parent, content)
    parent.store.comments ||= Timeline.create
    parent.store.comments.add_post(Post.create(self, content))
  end

  index_accessor :username

  property      :username,          String
  property      :salt,              String
  property      :hashed_password,   String
  list_property :notifications,     Integer
  property      :my_posts,          Timeline # 自分の投稿
  property      :primary_timeline,  Timeline # 自分のホームページに出るTL
  set_property  :watchers,          Timeline # 自分の投稿をウォッチしてるTL
end
