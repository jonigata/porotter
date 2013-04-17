# -*- coding: utf-8 -*-

class PostHolder < RedisMapper::PlatformModel
  def self.create(post)
    self.new_instance.tap do |holder|
      holder.store.post = post
      holder.store.removed = false
    end
  end

  def mark_as_removed(f)
    self.store.removed = f
  end

  delegate :post    do self.store end
  delegate :removed do self.store end

  property  :post       ,Post
  property  :removed    ,Boolean
end
