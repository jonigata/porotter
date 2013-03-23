# -*- coding: utf-8 -*-

class Notifiee
  def initialize
    # @watchers[timeline_id] = [session_id, ...]
    @watchers = Hash.new { |h, k| h[k] = Set.new }
    # @watchees[session_id] = Set.new
    @watchees = Hash.new
  end

  def set_targets(session, data)
    begin 
      targets = data["targets"].map { |e| e.to_i }

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
    target_id, version = JSON.parse(message)
    deleted = []
    @watchers[target_id].each do |session|
      if @watchees.member?(session) && @watchees[session].member?(target_id)
        yield target_id, version, session
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

