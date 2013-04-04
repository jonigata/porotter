# -*- coding: utf-8 -*-

class Spotter < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |sentry|
    end
  end

  def add_member(member)
    self.store.members.add(member)
  end

  property  :access_rank,   Symbol      # :public, :closed, :private
  property  :members,       Group
end
