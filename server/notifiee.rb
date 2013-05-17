# -*- coding: utf-8 -*-

class Notifiee
  def initialize
    # @watchers[object_id] = [session_id, ...]
    @watchers = Hash.new { |h, k| h[k] = Set.new }
    # @watchees[session_id] = Set.new
    @watchees = Hash.new
  end

  def set_targets(session, targets)
    begin 
      # targetsから要素が削除されている場合、
      # watchers[some]にはsessionが含まれているのに
      # watchees[session]にはsomeが含まれていないケースが生じるが、
      # その判定はlazyに(通知時に)行う。

      @watchees[session] = Set.new(targets)
      targets.each do |target_id|
        @watchers[target_id] << session
      end
    rescue => e
      puts e
      puts e.backtrace
    end
  end

  def trigger(message)
    target_id, info = JSON.parse(message)
    deleted = []
    @watchers[target_id].each do |session|
      if @watchees.member?(session) && @watchees[session].member?(target_id)
        yield target_id, info, session
      else
        deleted.push session
      end
    end
    @watchers[target_id].subtract(deleted)
  end

  def remove_session(session)
    @watchees.delete(session)
  end
end

class ObserversNotifiee < Notifiee
  def key
    :'watch-observers'
  end

  def handle_message(io, message)
    EM.next_tick do
      self.trigger(message) do |board_id, observers, session|
        puts "send board watch message: #{board_id}"
        io.push key, {:board => board_id, :observers => observers}, {:to => session }
      end
    end
  end
end

class TimelineNotifiee < Notifiee
  def key
    :'watch-timeline'
  end

  def handle_message(io, message)
    EM.next_tick do
      self.trigger(message) do |timeline_id, version, session|
        # puts "send timeline watch message: #{timeline_id}"
        io.push key, {:timeline => timeline_id, :version => version}, {:to => session }
      end
    end
  end
end

class PostNotifiee < Notifiee
  def key
    :'watch-post'
  end

  def handle_message(io, message)
    EM.next_tick do
      post_notifiee.trigger(message) do |post_id, version, session|
        # puts "send post watch message: #{post_id}"
        io.push key, {:post => post_id, :version => version}, {:to => session }
      end
    end
  end
end

def start_watch
  redis = Redis.new

  notifiees = {}
  [ObserversNotifiee.new, TimelineNotifiee.new, PostNotifiee.new].each do |n|
    notifiees[n.key.to_s] = n
  end

  users = Hash.new # { session => { :user => user-id, :board => board-id } }

  io = Sinatra::RocketIO
  io.on :connect do |session, type|
    puts "new client <#{session}> (type:#{type})"
  end

  io.on :disconnect do |session, type|
    puts "delete client <#{session}> (type:#{type})"

    user_info = users[session]
    if user_info 
      user_id = user_info[:user]
      board_id = user_info[:board]

      Board.attach_if_exist(board_id).tap do |board|
        board.remove_observer(User.attach_if_exist(user_id)) if board
      end
    end
    notifiees.each do |k, n|
      n.remove_session(session)
    end
  end

  io.on :describe do |data, session, type|
    user_id = data["user"].to_i
    board_id = data["board"].to_i

    users[session] = user_info = { :user => user_id, :board => board_id }

    Board.attach_if_exist(board_id).tap do |board|
      board.add_observer(User.attach_if_exist(user_id)) if board
    end
  end

  notifiees.each do |key, notifiee|
    io.on key do |data, session, type|
      # puts "#{notifiee.key} params: #{data}, <#{session}> type: #{type}"
      notifiee.set_targets(session, data["targets"].map { |e| e.to_i })
    end
  end

  keys = notifiees.map { |k, v| v.key }
  p keys

  EM.defer do
    # publishと同じRedisインスタンスを使うとブロックする
    Redis.new.subscribe(*keys) do |on|
      on.message do |channel, message|
        puts "get #{channel} singal(#{message})"
        notifiees[channel].handle_message(io, message)
      end
    end
  end
end
