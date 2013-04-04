# -*- coding: utf-8 -*-

class Ribbon < RedisMapper::PlatformModel
  def self.create
    self.new_instance.tap do |ribbon|
    end
  end

  property      :owner,     Board
  property      :type,      Symbol
  property      :content,   RibbonContent
end
