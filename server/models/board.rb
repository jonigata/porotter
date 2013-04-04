# -*- coding: utf-8 -*-

class Board < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |board|
    end
  end

  property      :owner,     User
  list_property :ribbons,   Ribbon
  property      :sentry,    Spotter
end
