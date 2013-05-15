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

def start_watch
  redis = Redis.new

  board_notifiee = Notifiee.new
  timeline_notifiee = Notifiee.new
  post_notifiee = Notifiee.new

  users = Hash.new # { session => { :user => user-id, :board => board-id } }
  observers =
    Hash.new { |h, k| h[k] = Set.new } # { board-id => [user-id, ...] }

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

      board_observers = observers[board_id]
      board_observers.delete(user_id)

      redis.publish("board-watcher", [board_id, board_observers.to_a].to_json)
    end
    board_notifiee.remove_session(session)
    timeline_notifiee.remove_session(session)
    post_notifiee.remove_session(session)
  end

  io.on :describe do |data, session, type|
    user_id = data["user"].to_i
    board_id = data["board"].to_i

    users[session] = user_info = { :user => user_id, :board => board_id }

    board_observers = observers[board_id]
    board_observers << user_id

    redis.publish("board-watcher", [board_id, board_observers.to_a].to_json)
  end

  io.on :'watch-timeline' do |data, session, type|
    # puts "watch-timeline params: #{data}, <#{session}> type: #{type}"
    timeline_notifiee.set_targets(session, data["targets"].map { |e| e.to_i })
  end

  io.on :'watch-post' do |data, session, type|
    # puts "watch-post params: #{data}, <#{session}> type: #{type}"
    post_notifiee.set_targets(session, data["targets"].map { |e| e.to_i })
  end

  io.on :'watch-board' do |data, session, type|
    puts "watch-board params: #{data}, <#{session}> type: #{type}"
    board_notifiee.set_targets(session, data["targets"].map { |e| e.to_i })
  end

  EM.defer do
    Redis.new.subscribe( # publishと同じのを使うとブロックする
      "timeline-watcher",
      "post-watcher",
      "board-watcher") do |on|
      on.message do |channel, message|
        case channel
        when "timeline-watcher"
          # puts "get timeline-watcher singal(#{message})"
          EM.next_tick do
            timeline_notifiee.trigger(message) do |timeline_id, version, session|
              # puts "send timeline watch message: #{timeline_id}"
              io.push :'watch-timeline', {:timeline => timeline_id, :version => version}, {:to => session }
            end
          end
        when "post-watcher"
          # puts "get post-watcher singal(#{message})"
          EM.next_tick do
            post_notifiee.trigger(message) do |post_id, version, session|
              # puts "send post watch message: #{post_id}"
              io.push :'watch-post', {:post => post_id, :version => version}, {:to => session }
            end
          end
        when "board-watcher"
          # puts "get post-watcher singal(#{message})"
          EM.next_tick do
            board_notifiee.trigger(message) do |board_id, observers, session|
              puts "send board watch message: #{board_id}"
              io.push :'watch-board', {:board => board_id, :observers => observers}, {:to => session }
            end
          end
        end
      end
    end
  end
end
