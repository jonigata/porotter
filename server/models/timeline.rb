# -*- coding: utf-8 -*-

class Timeline < RedisMapper::PlatformModel
  def self.create(owner)
    self.new_instance.tap do |timeline|
      timeline.store.owner = owner
      timeline.store.version = 1
    end
  end

  def add_post(post)
    holder = self.store.post_to_holder[post]
    if !holder
      holder = PostHolder.create(post)
      self.store.post_to_holder[post] = holder
    else
      holder.mark_as_removed(false)
    end
    
    version_up do |version|
      post.refered_by(self)
      self.store.posts.add(version, holder)
    end

    self.store.watchers.each do |watcher|
      watcher.add_post(post)
    end
  end

  def remove_post(post)
    holder = self.store.post_to_holder[post] or return
    holder.mark_as_removed(true)
    version_up do |version|
      self.store.posts.add(version, holder)
    end
  end

  def member?(post)
    self.store.post_to_holder.member?(post)
  end

  def fetch(newest_score, oldest_score, count)
    puts "#### fetch newest_score = #{newest_score.inspect}, oldest_score = #{oldest_score.inspect}, count = #{count.inspect}"

    # 1.[newest_score, oldest_score)に有効要素がない場合
    #   → [[], nil, nil]を返す
    # 
    # 2.有効要素がある場合
    #   →
    #     [
    #       [有効要素0, ..., 有効要素N](A),
    #       score(有効要素0),
    #       [score(next(有効要素N)), oldest_score].min
    #     ]
    # を返す。
    # Aの長さはcount以下とは限らない(削除情報が入ることがあるため)。

    oldest_score ||= 0
    
    # newest_score, oldest_scoreがnilの場合無限を指す
    b = newest_score || :inf
    e = RedisMapper.exclusive(oldest_score)

    posts = self.store.posts
    res_newest_score = nil
    res_oldest_score = nil
    result_array = []
    rest_count = count + 1

    while 0 < rest_count
      a = posts.revrange(b, e, [0, rest_count])
      break if a.empty?

      res_newest_score ||= a.first[:score]
      res_oldest_score = a.last[:score]

      a.each do |x|
        score = x[:score]
        value = x[:value]
        removed = value.removed
        result_array.push([score, removed, value.post])
        rest_count -= 1 unless removed
      end

      b = RedisMapper.exclusive(res_oldest_score)
      puts "result_array.length = #{result_array.length}, rest_count = #{rest_count}"
    end

    return [[], nil, nil] if result_array.empty?

    if rest_count == 0
      result_array.pop
    else
      res_oldest_score = oldest_score
    end

    puts "#### fetch result: res_newest_score = #{res_newest_score.inspect}, res_oldest_score = #{res_oldest_score.inspect}"
    [
      result_array,
      res_newest_score,
      res_oldest_score
    ]
  end

  def length
    self.store.posts.length
  end

  def empty?
    self.store.posts.empty?
  end

  def on_post_modified(post)
    # bump up
    holder = self.store.post_to_holder[post]
    if self.store.posts.last_value != holder
      version_up do |version|
        self.store.posts.add(version, holder)
      end
    end
  end

  def watch(target)
    target.store.watchers.add(self)
  end

  def move_post(source, target)
    # sourceをbump up
    # puts "bump up(source): #{source.store.id}"
    source_holder = self.store.post_to_holder[source]
    if !source_holder
      source_holder = PostHolder.create(source)
      self.store.post_to_holder[source] = source_holder
    else
      source_holder.mark_as_removed(false)
    end
    self.store.posts.add(self.store.version_incr(1), source_holder)

    # source->targetをbump up
    newest_score = RedisMapper.exclusive(self.store.posts.score(source_holder))
    oldest_score = :'-inf'
    if target
      target_holder = self.store.post_to_holder[target]
      # puts "target_holder.store.id = #{target_holder.store.id}"
      oldest_score =
        RedisMapper.exclusive(self.store.posts.score(target_holder))
    end

    # puts "oldest_score = #{oldest_score}, newest_score = #{newest_score}"
    self.store.posts.range(oldest_score, newest_score).each do |e|
      # puts "bump up(target): score = #{e[:score]} post.store.id = #{e[:value].post.store.id}, post.store.content = \"#{e[:value].post.store.content}\""
      self.store.posts.add(self.store.version_incr(1), e[:value])
    end

    redis.publish(
      "timeline-watcher", [self.store.id, self.store.version].to_json)
  end

  def transfer_post_from(source_timeline, source, target)
    # puts "transfer_post_from source.store.id = #{source.store.id}, target.store.id = #{target && target.store.id}"
    move_post(source, target)
    source_timeline.remove_post(source)
  end

  private
  def version_up
    self.store.version_incr(1).tap do |version|
      yield version
      redis.publish("timeline-watcher", [self.store.id, version].to_json)
    end
  end    

  property              :owner,             User
  property              :version,           Integer
  ordered_set_property  :posts,             PostHolder
  dictionary_property   :post_to_holder,    Post, PostHolder
  set_property          :watchers,          Timeline
end
