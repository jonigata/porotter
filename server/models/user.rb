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

        board = Board.create(user, 'global')
        user.store.boards[board_tag(user, "global")] = board
        
        ribbon = board.make_ribbon('井戸端会議')
        ribbon.set_readability(:everyone, nil)
        ribbon.set_writability(:everyone, nil)
        ribbon.set_editability(:private_group, [])
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

      global_timeline = World.singleton.global_timeline

      self.make_index(:username, username) do 
        self.new_instance do |user|
          user.store.username = username
          salt = Misc.new_salt
          user.store.label = user.store.username
          user.store.email = ''
          user.store.salt = salt
          user.store.hashed_password = Misc.hash_pw(salt, password)

          board = Board.create(user, 'マイボード')
          user.store.boards[board_tag(user, "マイボード")] = board
          user.store.start_board = board
            
          global_ribbon = self.global_ribbon

          board.import_ribbon(global_ribbon)
          user.store.my_posts = 
            board.make_readonly_ribbon('あなたの投稿').timeline
          user.store.favorites = 
            board.make_readonly_ribbon('お気に入り').timeline

          user.add_article(global_ribbon, :Tweet, "最初の投稿です")

          World.singleton.add_user(user)
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
    Post.create(self, type, content, true).tap do |post|
      ribbon.add_article(post)
      self.store.my_posts.add_post(post)
    end
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

  def add_board(label)
    tag = board_tag(self, label)
    raise if self.store.boards.member?(tag)
    board = Board.create(self, label)
    self.store.boards[tag] = board
  end

  def find_board(label)
    self.store.boards[board_tag(self, label)]
  end

  def rename_board(board, label)
    tag = board_tag(self, board.label)
    self.store.boards.remove(tag)
    board.set_label(label)
    self.store.boards[board_tag(self, label)] = board
  end

  def add_ribbon(board, label)
    board.make_ribbon(label)
  end

  def remove_ribbon(board, ribbon)
    # TODO: ribbonチェック
    board.remove_ribbon(ribbon)
  end

  def rename_ribbon(ribbon, label)
    ribbon.owner.rename_ribbon(ribbon, label)
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

  def join_board(board)
    self.store.boards[board_tag(board.owner, board.label)] = board
  end

  def join_ribbon(board, ribbon)
    board.add_ribbon(ribbon)
  end

  def restore_ribbon(board, ribbon)
    board.restore_ribbon(ribbon)
  end

  private
  def self.global_ribbon
    return self.store_class.find_by_username('global').find_board('global').first_ribbon
  end

  def self.board_tag(user, label)
    "#{user.username}\n#{label}"
  end

  def board_tag(user, label)
    self.class.board_tag(user, label)
  end

  index_accessor :username

  delegate :username        do self.store end
  delegate :label           do self.store end
  delegate :email           do self.store end
  delegate :start_board     do self.store end

  property              :username,          String
  property              :label,             String
  property              :email,             String
  property              :salt,              String
  property              :hashed_password,   String
  list_property         :notifications,     Integer
  property              :my_posts,          Timeline # 自分の投稿
  property              :favorites,         Timeline # 自分のお気に入り
  dictionary_property   :boards,            String, Board
  property              :start_board,       Board
end
