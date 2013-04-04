# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  def self.create(access_rank)
    self.new_instance.tap do |board|
      board.store.spotter = Spotter.create(access_rank)
    end
  end

  def add_member(member)
    self.store.spotter.add_member(member)
  end

  property      :owner,     User
  list_property :ribbons,   Ribbon
  property      :sentry,    Spotter
end
