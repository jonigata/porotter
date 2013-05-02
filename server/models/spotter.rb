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

  delegate :type            do self.store end
  delegate :unique_group    do self.store end

  property  :type,          Symbol      # :read, :write, :edit
  property  :permission,    Symbol      # :everyone, :outsource, :group
  property  :group,         Group
  property  :source,        Spotter
  property  :unique_group,  Group
end

module SpotterHolder
  def format_readability
    format_permission(self.store.read_spotter)
  end

  def format_writability
    format_permission(self.store.write_spotter)
  end

  def format_editability
    format_permission(self.store.edit_spotter)
  end

  def secret?
    return self.store.read_spotter.secret?
  end

  def readable_by?(user)
    return self.store.read_spotter.permitted?(user)
  end

  def writable_by?(user)
    return self.store.write_spotter.permitted?(user)
  end

  def editable_by?(user)
    return self.store.edit_spotter.permitted?(user)
  end

  # 以下permision => groupは
  # :everyon => nil
  # :public_group => Group
  # :private_group => Array
  # :same_as_read => nil
  # :same_as_write => nil

  def set_readability(permission, group)
    set_ability(self.store.read_spotter, permission, group)
  end
  
  def set_writability(permission, group)
    set_ability(self.store.write_spotter, permission, group)
  end
  
  def set_editability(permission, group)
    set_ability(self.store.edit_spotter, permission, group)
  end
  
  private
  def set_ability(spotter, permission, group)
    case permission
    when :everyone
      spotter.set_permission(:everyone)
    when :public_group
      spotter.set_permission(group)
    when :private_group
      spotter.set_permission(group)
    when :same_as_readable
      spotter.set_permission(self.read_spotter)
    when :same_as_writable
      spotter.set_permission(self.write_spotter)
    when :same_as_board
      soptter.set_permission(self.parent_spotter(spotter.type))
    end    
  end
  
  def format_permission(spotter)
    {
      :everyone => false,
      :public_group => false,
      :private_group => false,
      :same_as_read => false,
      :same_as_write => false,
      :same_as_board => false,
    }.tap do |result|
      permission = spotter.store.permission
      case permission
      when :everyone
        result[:everyone] = true
      when :outsource
        source = spotter.store.source
        if source == self.store.read_spotter
          result[:same_as_read] = true
        elsif source == self.store.write_spotter
          result[:same_as_write] = true
        elsif source == self.parent_spotter(spotter.type)
          result[:same_as_board] = true
        end
      when :group
        result[spotter.unique? ? :private_group : :public_group] = true
      end
    end
  end

  delegate :read_spotter                do self.store end
  delegate :write_spotter               do self.store end
  delegate :edit_spotter                do self.store end

  delegate :readble_by?, :permitted?    do self.store.read_spotter end
  delegate :writable_by?, :permitted?   do self.store.write_spotter end
  delegate :editable_by?, :permitted?   do self.store.edit_spotter end

end
