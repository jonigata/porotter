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

      global_timeline = Users.singleton.store.global_timeline

      self.make_index(:username, username) do 
        self.new_instance do |user|
          user.store.username = username
          salt = Misc.new_salt
          user.store.label = user.store.username
          user.store.email = ''
          user.store.salt = salt
          user.store.hashed_password = Misc.hash_pw(salt, password)

          board = Board.create(user, 'マイボード', :private, :private)
          user.store.board = board
            
          my_posts = Timeline.create(user, 'あなたの投稿', :public, :private)
          user.store.my_posts = my_posts
          global_timeline.watch(my_posts)

          favorites = Timeline.create(user, 'お気に入り', :public, :private)
          user.store.favorites = favorites

          board.import(global_timeline, my_posts)
          board.import(my_posts, nil)
          board.import(favorites, nil)

          my_posts.add_post(Post.create(self, :Tweet, "最初の投稿です"))

          Users.singleton.add_user(user)
        end
      end or raise "That username is taken."
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

  def add_article(ribbon, type, content)
    Post.create(self, type, content).tap do |post|
      ribbon.add_article(post)
    end
  end

  def add_comment(ribbon, parent, type, content)
    Post.create(self, type, content).tap do |post|
      ribbon.add_comment(parent, post)
    end
  end

  def favor(post)
    self.store.favorites.add_post(post)
    post.favored_by(self)
  end

  def unfavor(post)
    self.store.favorites.remove_post(post)
    post.unfavored_by(self)
  end

  def favors?(post)
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
  property      :favorites,         Timeline # 自分のお気に入り
  property      :board,             Board
end
