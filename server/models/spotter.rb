# -*- coding: utf-8 -*-

class Spotter < RedisMapper::PlatformModel
  def self.create(type, permission)
    raise unless [:read, :write, :edit].member?(type)
    check_permission(permission)
    
    self.new_instance.tap do |spotter|
      spotter.store.type = type
      spotter.store.unique_group = Group.create("#{type}固有グループ", false)
      spotter.set_permission_no_check(permission)
    end
  end

  def self.check_permission(permission)
    case permission
    when Symbol
      raise "unknown permission: #{permission.inspect}" if
        permission != :everyone
    when Array
      permission.each do |m|
        raise "unexpected array element: #{m.inspect}" unless m.kind_of?(User)
      end
    when Spotter
      # do nothing
    when Group
      # do nothing
    else
      raise "unexpected data type"
    end
  end

  def set_permission(permission)
    self.class.check_permission(permission)
    set_permission_no_check(permission)
  end

  def unique?
    raise if self.store.permission != :group
    self.store.unique_group == self.store.group
  end

  def secret?
    return self.store.permission != :everyone
  end

  def permitted?(user)
    case self.store.permission
    when :everyone
      return true
    when :outsource
      return self.store.source.permitted?(user)
    when :group
      return self.store.group.member?(user)
    end
    raise
  end

  def set_permission_no_check(permission)
    case permission
    when Symbol
      self.store.permission = permission
    when Array
      unique_group = self.store.unique_group
      unique_group.set(permission)
      self.store.group = unique_group
      self.store.permission = :group
    when Spotter
      # TODO: 循環チェック
      self.store.source = permission
      self.store.permission = :outsource
    when Group
      self.store.group = permission
      self.store.permission = :group
    end
  end

  delegate :unique_group    do self.store end

  property  :type,          Symbol      # :read, :write, :edit
  property  :permission,    Symbol      # :everyone, :outsource, :group
  property  :group,         Group
  property  :source,        Spotter
  property  :unique_group,  Group
end
