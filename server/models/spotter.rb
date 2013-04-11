# -*- coding: utf-8 -*-

class Spotter < RedisMapper::PlatformModel
  def self.create(readable, writable)
    self.new_instance.tap do |spotter|
      spotter.store.readable = readable
      spotter.store.writable = writable
    end
  end

  def clone
    self.class.new_instance.tap do |it|
      it.store.readable = self.store.readable
      it.store.writable = self.store.writable
    end
  end

  def secret?
    !self.store.readable.nil?
  end

  property  :readable,  Group # nil means fully public
  property  :writable,  Group # nil means fully public
end
