# -*- coding: utf-8 -*-

class Spotter < RedisMapper::PlatformModel
  def self.create(readable, writable)
    if readable.kind_of?(Symbol)
      raise if readable != :everyone
    else
      raise unless readable.kind_of?(Group)
    end
    if writable.kind_of?(Symbol)
      raise if writable != :everyone && writable != :same_as_readable
    else
      raise unless writable.kind_of?(Group)
    end
    
    self.new_instance.tap do |spotter|
      if readable.kind_of?(Symbol)
        spotter.store.readable_type = readable
      else
        spotter.store.readable_type = :group
        spotter.store.readable_group = readable
      end
      
      if writable.kind_of?(Symbol)
        spotter.store.writable_type = writable
      else
        spotter.store.writable_type = :group
        spotter.store.writable_group = writable
      end
    end
  end

  def clone
    self.class.new_instance.tap do |it|
      it.store.readable = self.store.readable
      it.store.writable = self.store.writable
    end
  end

  def secret?
    self.store.readable_type != :everyone
  end

  def editable_by?(user)
    return false unless user
    writable_type = self.store.writable_type
    return true if writable_type == :everyone
    if writable_type == :same_as_readable
      readable_type = self.store.readable_type 
      return true if readable_type == :everyone
      return true if readable_group.member?(user)
      return false
    else
      self.store.writable_group.member?(user)
    end
  end

  property  :readable_type,     Symbol  # :everyone, :group
  property  :readable_group,    Group 
  property  :writable_type,     Symbol  # :everyone, :group, :same_as_readable
  property  :writable_group,    Group
end
