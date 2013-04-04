# -*- coding: utf-8 -*-
class SignUpError < Exception; end

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
          user.store.label = user.store.username
          user.store.email = ''
          user.store.salt = salt
          user.store.hashed_password = Misc.hash_pw(salt, password)

          user.store.my_posts = Timeline.create
          user.store.primary_timeline = Timeline.create
          user.store.favorites = Timeline.create
          user.store.watchers.add(Users.singleton.store.global_timeline)
          user.store.watchers.add(user.store.my_posts)
          user.store.watchers.add(user.store.primary_timeline)
          user.add_article("最初の投稿です")

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

  def add_article(type, content)
    Post.create(self, type, content).tap do |post|
      self.store.watchers.each do |tl|
        tl.add_post(post)
      end
    end
  end

  def add_comment(parent, type, content)
    parent.add_comment(self, type, content)
  end

  def toggle_favorite(post)
    self.store.favorites ||= Timeline.create
    if !favors?(post)
      self.store.favorites.add_post(post)
      post.favored_by(self)
    else
      self.store.favorites.remove_post(post)
      post.unfavored_by(self)
    end
  end

  def favors?(post)
    self.store.favorites ||= Timeline.create
    self.store.favorites.member?(post)
  end

  index_accessor :username

  property      :username,          String
  property      :label,             String
  property      :email,             String
  property      :salt,              String
  property      :hashed_password,   String
  list_property :notifications,     Integer
  property      :my_posts,          Timeline # 自分の投稿
  property      :primary_timeline,  Timeline # 自分のホームページに出るTL
  property      :favorites,         Timeline # 自分のお気に入り
  set_property  :watchers,          Timeline # 自分の投稿をウォッチしてるTL
end
