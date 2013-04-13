# -*- coding: utf-8 -*-

class SignUpError < Exception; end

class Group < RedisMapper::PlatformModel; end
class Board < RedisMapper::PlatformModel; end
class Timeline < RedisMapper::PlatformModel; end

class User < RedisMapper::PlatformModel
  def self.create_global(password)
    # init_platformから１度だけ呼び出される
    username = 'global'

    self.make_index(:username, username) do 
      self.new_instance do |user|
        user.store.username = username
        salt = Misc.new_salt
        user.store.label = user.store.username
        user.store.email = ''
        user.store.salt = salt
        user.store.hashed_password = Misc.hash_pw(salt, password)

        board = Board.create(user, 'global', '井戸端会議', nil, nil)
        user.store.boards['global'] = board
        
        global_timeline = Users.singleton.store.global_timeline
        board.import(global_timeline, nil)

        Users.singleton.add_user(user)
      end
    end

  end

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

          private_group = Group.create
          private_group.add_member(user)
          user.store.private_group = private_group

          board = Board.create(
            user, 'myboard', 'マイボード', private_group, private_group)
          user.store.boards['myboard'] = board
            
          my_posts = Timeline.create(user, 'あなたの投稿')
          user.store.my_posts = my_posts
          global_timeline.watch(my_posts)

          favorites = Timeline.create(user, 'お気に入り')
          user.store.favorites = favorites

          board.import(global_timeline, my_posts)
          board.import(my_posts, nil)
          board.import(favorites, nil)

          my_posts.add_post(Post.create(user, :Tweet, "最初の投稿です", true))

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
    # TODO: ribbonチェック
    ribbon.add_article(Post.create(self, type, content, true))
  end

  def add_comment(ribbon, parent, type, content)
    # TODO: ribbonチェック
    ribbon.add_comment(parent, Post.create(self, type, content, false))
  end

  def favor(ribbon, post)
    # TODO: ribbonチェック
    self.store.favorites.add_post(post)
    post.favored_by(self)
  end

  def unfavor(ribbon, post)
    # TODO: ribbonチェック
    self.store.favorites.remove_post(post)
    post.unfavored_by(self)
  end

  def favors?(post)
    # TODO: ribbonチェック
    self.store.favorites.member?(post)
  end

  def add_board(name, label)
    private_group = self.store.private_group
    board = Board.create(self, name, label, private_group, private_group)
    self.store.boards[name] = board
  end

  def find_board(idname)
    self.store.boards[idname]
  end

  def add_ribbon(board, label)
    timeline = Timeline.create(self, label)
    board.import(timeline, timeline)
  end

  def remove_ribbon(ribbon)
    # TODO: ribbonチェック
    ribbon.store.owner.remove_ribbon(ribbon)
  end

  def edit_permission(ribbon, permission)
    # TODO: ribbonチェック
    p permission
    case permission
    when :public
      ribbon.set_spotter(nil)
    when :private
      private_group = self.store.private_group
      ribbon.set_spotter(Spotter.create(private_group, private_group))
    end
  end

  index_accessor :username

  property              :username,          String
  property              :label,             String
  property              :email,             String
  property              :salt,              String
  property              :hashed_password,   String
  list_property         :notifications,     Integer
  property              :my_posts,          Timeline # 自分の投稿
  property              :favorites,         Timeline # 自分のお気に入り
  dictionary_property   :boards,            String, Board
  property              :private_group,     Group   # 自分だけのグループ
end
