# -*- coding: utf-8 -*-

require_relative "misc.rb"
require_relative "structure.rb"

class Object
  def self.from_redis(s)
    self.from_s(s)
  end

  def to_redis
    to_s
  end
end

class Time
  def to_redis
    to_i
  end
end

module RedisMapper

  class Model
    #
    # データ構造マッパ
    #
    class ModelStructureBase
      include Enumerable 

      def initialize(redis, root_key, key_restriction, value_restriction)
        @redis = redis
        @root_key = root_key
        @key_restriction = key_restriction
        @value_restriction = value_restriction
      end

      def key_typecheck(key)
        raise "type mismatch: #{key.inspect} for #{@key_restriction}" unless
          @key_restriction.contains?(key)
      end

      def value_typecheck(value)
        raise "type mismatch: #{value.inspect} for #{@value_restriction}" unless
          @value_restriction.contains?(value)
      end

      def typecheck(value)
        value_typecheck(value)
      end

      def key_restriction
        @key_restriction
      end
      def value_restriction
        @value_restriction
      end
      def restriction
        @value_restriction
      end

      attr_reader :redis
      attr_reader :root_key
    end

    class ModelDictionary < ModelStructureBase
      def [](key)
        key_typecheck(key)
        restriction.from_redis(redis.hget(root_key, key.to_redis))
      end

      def []=(key, val)
        key_typecheck(key)
        typecheck(val)
        redis.hset(root_key, key.to_redis, val.to_redis)
      end

      def length
        redis.hlen(root_key)
      end

      def empty?
        length == 0
      end

      def member?(key)
        redis.hexists(root_key, key.to_redis)
      end

      def keys
        redis.hkeys(root_key).map do |k|
          key_restriction.from_redis(k)
        end
      end

      def values
        redis.hvals(root_key).map do |v|
          restriction.from_redis(v)
        end
      end

      def each
        redis.hgetall(root_key).each do |key, val|
          yield key_restriction.from_redis(key), restriction.from_redis(val)
        end
      end

      def to_h
        Hash.new.tap do |h|
          redis.hgetall(root_key).each do |key, val|
            h[key_restriction.from_redis(key)] = restriction.from_redis(val)
          end
        end
      end

      def to_a
        Array.new.tap do |a|
          redis.hgetall(root_key).each do |key, val|
            a.push([key_restriction.from_redis(key), restriction.from_redis(val)])
          end
        end
      end

      def incr(key, delta)
        key_typecheck(key)
        redis.hincrby(root_key, key.to_redis, delta)
      end

      def incr_if(key, delta)
        key_typecheck(key)
        while true
          redis.watch root_key
          old_value = redis.hget(root_key, key.to_redis).to_i
          if !yield old_value
            redis.unwatch
            return false
          end
          redis.multi do 
            redis.hincrby(root_key, key.to_redis, delta)
          end and break
        end
      end

      def clear
        redis.del(root_key)
      end

      def remove(key)
        key_typecheck(key)
        redis.hdel(root_key, key.to_redis)
      end

      def remove_array(a)
        if !a.empty?
          redis.hdel(root_key, a.map { |x| typecheck(x); x.to_redis })
        end
      end

      def set_if_not_exist(key, val)
        key_typecheck(key)
        typecheck(val);
        redis.hsetnx(root_key, key.to_redis, val.to_redis)
      end
    end

    class ModelScoreMap < ModelStructureBase
      def [](key)
        key_typecheck(key)
        Integer.from_redis(redis.zscore(root_key, key.to_redis))
      end

      def []=(key, val)
        key_typecheck(key)
        typecheck(val)
        redis.zadd(root_key, val.to_redis, key.to_redis)
      end

      def length
        redis.zcard(root_key)
      end

      def member?(key)
        redis.zscore(root_key, key.to_redis) ? true : false
      end

      def each
        redis.zrange(root_key, 0, -1, :withscores => true).each do |key, val|
          yield key_restriction.from_redis(key), Integer.from_redis(val)
        end
      end

      def to_h
        Hash.new.tap do |h|
          redis.zrange(root_key, 0, -1, :withscores => true).each do |key, val|
            h[key_restriction.from_redis(key)] = Integer.from_redis(val)
          end
        end
      end

      def to_a
        Array.new.tap do |a|
          redis.zrange(root_key, 0, -1, :withscores => true).each do |key, val|
            a.push([key_restriction.from_redis(key), Integer.from_redis(val)])
          end
        end
      end

      def incr(key, delta)
        key_typecheck(key)
        redis.zincrby(root_key, delta, key.to_redis)
      end

      def incr_if(key, delta)
        key_typecheck(key)
        while true
          redis.watch root_key
          old_value = redis.zscore(root_key, key.to_redis).to_i
          if !yield old_value
            redis.unwatch
            return false
          end
          redis.multi do 
            redis.zincrby(root_key, delta, key.to_redis)
          end and break
        end
      end

      def clear
        redis.del(root_key)
      end

      def remove(key)
        key_typecheck(key)
        redis.zrem(root_key, key.to_redis)
      end

      def range(lower, upper)
        raise "score_map score must be Integer" unless lower.kind_of?(Integer)
        raise "score_map score must be Integer" unless upper.kind_of?(Integer)
        redis.zrange(root_key, lower, upper, :withscores => true).map do |k, v|
          [key_restriction.from_redis(k), Integer.from_redis(v)]
        end
      end

      def remove_array(a)
        if !a.empty?
          redis.zrem(root_key, a.map { |x| typecheck(x); x.to_redis })
        end
      end
    end

    class ModelList < ModelStructureBase
      def unshift(val)
        typecheck(val)
        redis.lpush(root_key, val.to_redis)
      end

      def push(val)
        typecheck(val)
        redis.rpush(root_key, val.to_redis)
      end

      def shift
        e = redis.lpop(root_key)
        e && restriction.from_redis(e)
      end

      def blocking_shift(timeout)
        e = redis.blpop(root_key, timeout)
        e && restriction.from_redis(e[1])
      end

      def range(m, n)
        redis.lrange(root_key, m, n).map do |val|
          restriction.from_redis(val)
        end
      end

      def remove(val)
        typecheck(val)
        redis.lrem(root_key, 1, val.to_redis)
      end

      def trim(m, n)
        redis.ltrim(m, n)
      end

      def each
        redis.lrange(root_key, 0, -1).each do |val|
          yield restriction.from_redis(val)
        end
      end

      def length
        redis.llen(root_key)
      end

      def empty?
        length == 0
      end

      def trim(b, e)
        redis.ltrim(root_key, b, e)
      end

      def clear
        redis.del(root_key)
      end

      def to_a
        range(0, -1)
      end
    end

    class ModelArray < ModelStructureBase
      def [](key)
        raise "array index must be Integer" unless key.kind_of?(Integer)
        restriction.from_redis(redis.hget(root_key, key))
      end

      def []=(key, val)
        raise "array index must be Integer" unless key.kind_of?(Integer)
        typecheck(val)
        redis.hset(root_key, key, val.to_redis)
      end

      def member?(val)
        typecheck(val)
        redis.hvals(root_key).member?(val.to_s)
      end

      def each
        h = redis.hgetall(root_key)
        Hash.new.tap do |nh|
          m = 0
          h.each do |k, v|
            n = k.to_i
            m = m < n ? n : m
            nh[n] = restriction.from_redis(v)
          end

          (0..m).each do |i|
            yield nh[i]
          end
        end
      end
    end

    class ModelSet < ModelStructureBase
      def add(value)
        typecheck(value)
        redis.sadd(root_key, value.to_redis)
      end

      def remove(value)
        typecheck(value)
        redis.srem(root_key, value.to_redis);
      end

      def member?(value)
        typecheck(value)
        redis.sismember(root_key, value.to_redis)
      end

      def length
        redis.scard(root_key)
      end

      def empty?
        length == 0
      end

      def each
        a = redis.smembers(root_key)
        a.each do |e|
          yield restriction.from_redis(e)
        end
      end

      def sample
        e = redis.srandmember(root_key)
        e && restriction.from_redis(e)
      end

      def to_h
        Hash.new.tap do |h|
          self.each do |v|
            h[v] = v
          end
        end
      end

      def clear
        redis.del(root_key)
      end

      def pop
        restriction.from_redis(redis.spop(root_key))
      end

      def merge!(s)
        redis.sunionstore(root_key, root_key, s.root_key)
      end

      def raw
        redis.smembers(root_key).map do |x|
          Integer.from_s(x)
        end
      end
    end

    class ModelOrderedSet < ModelStructureBase
      def range(lower, upper, limit = nil)
        raise "ordered_set lower score must be Integer or :'-inf'; passed = #{lower.inspect}" unless lower.kind_of?(Integer) || lower == :'-inf'
        raise "ordered_set upper score must be Integer or :inf or :'+inf'; passed = #{upper.inspect}" unless upper.kind_of?(Integer) || upper == :'+inf' || upper == :inf
        raise "limit argument must be [offset, count]: passed = #{limit.inspect}" unless limit.nil? || Structure.match(tuple_template(Integer, Integer), limit)
        opt = {:withscores => true}
        opt.merge!(:limit => limit) if limit
        redis.zrangebyscore(root_key, lower, upper, opt).map do |value, score|
          { :score => Integer.from_redis(score), :value => restriction.from_redis(value) }
        end
      end

      def revrange(upper, lower, limit = nil)
        raise "ordered_set lower score must be Integer or :'-inf'; passed = #{lower.inspect}" unless lower.kind_of?(Integer) || lower == :'-inf'
        raise "ordered_set upper score must be Integer or :inf or :'+inf'; passed = #{upper.inspect}" unless upper.kind_of?(Integer) || upper == :'+inf' || upper == :inf
        raise "limit argument must be [offset, count]: passed = #{limit.inspect}" unless limit.nil? || Structure.match(tuple_template(Integer, Integer), limit)
        opt = {:withscores => true}
        opt.merge!(:limit => limit) if limit
        redis.zrevrangebyscore(root_key, upper, lower, opt).map do |value, score|
          { :score => Integer.from_redis(score), :value => restriction.from_redis(value) }
        end
      end

      def add(score, value)
        raise "ordered_set score must be Integer: passed = #{score.inspect}" unless score.kind_of?(Integer)
        typecheck(value)
        redis.zadd(root_key, score, value.to_redis)
      end

      def remove(value)
        redis.zrem(root_key, value.to_redis)
      end

      def member?(value)
        typecheck(value)
        !redis.zscore(root_key, value.to_redis).nil?
      end

      def erase(lower, upper)
        raise "ordered_set lower score must be Integer: passed = #{lower.inpsect}" unless lower.kind_of?(Integer)
        raise "ordered_set upper score must be Integer: passed = #{upper.inpsect}" unless upper.kind_of?(Integer)
        redis.zremrangebyscore(root_key, lower, upper);
      end

      def erase_by_rank(lower, upper)
        raise "ordered_set lower score must be Integer: passed = #{lower.inpsect}" unless lower.kind_of?(Integer)
        raise "ordered_set upper score must be Integer: passed = #{upper.inpsect}" unless upper.kind_of?(Integer)
        redis.zremrangebyrank(root_key, lower, upper);
      end

      def clear
        redis.zremrangebyscore(root_key, :'-inf', :inf);
      end

      def length
        redis.zcard root_key
      end

      def empty?
        length == 0
      end

      def each(&block)
        each_range(:'-inf', :inf, &block)
      end

      def length_range(first, last)
        if last == -1 then last = :inf; end
        redis.zcount root_key, first, last
      end

      def each_range(first, last, &block)
        if last == -1 then last = :inf; end
        a = redis.zrangebyscore(root_key, first, last, {:withscores => true})
        a.each do |value, score|
          block.call Integer.from_redis(score), restriction.from_redis(value)
        end
      end

      def [](first, last)
        Array.new.tap do |a|
          each_range(first, last) do |score, value|
            a.push [score, value]
          end
        end
      end

      def range_by_rank(first, last)
        redis.zrange(root_key, first, last).map do |x|
          restriction.from_redis(x)
        end
      end

      def range_by_rank_with_score(first, last)
        a = redis.zrange(root_key, first, last, { :withscores => true })
        a.map do |value, score|
          [score, restriction.from_redis(value)]
        end
      end

      def range_by_revrank(first, last)
        redis.zrevrange(root_key, first, last).map do |x|
          restriction.from_redis(x)
        end
      end

      def range_by_revrank_with_score(first, last)
        a = redis.zrevrange(root_key, first, last, { :withscores => true })
        a.map do |value, score|
          [score, restriction.from_redis(value)]
        end
      end

      def each_by_rank(first, last)
        redis.zrange(root_key, first, last).each do |x|
          yield restriction.from_redis(x)
        end
      end

      def each_by_revrank(first, last)
        redis.zrevrange(root_key, first, last).each do |x|
          yield restriction.from_redis(x)
        end
      end

      def each_by_rank_with_score(first, last)
        a = redis.zrange(root_key, first, last, { :withscores => true })
        a.each do |value, score|
          yield Integer.from_redis(score), restriction.from_redis(value)
        end
      end

      def each_by_revrank_with_score(first, last)
        a = redis.zrevrange(root_key, first, last, { :withscores => true })
        a.each do |value, score|
          yield Integer.from_redis(score), restriction.from_redis(value)
        end
      end

      def score(value)
        redis.zscore(root_key, value.to_redis).to_i
      end

      def score_if_exist(value)
        if value
          redis.zscore(root_key, value.to_redis)
        end
      end

      def rank(value)
        redis.zrank(root_key, value.to_redis)
      end

      def revrank(value)
        redis.zrevrank(root_key, value.to_redis)
      end

      def upper_rank(value)
        upper_rank_by_score(self.score(value.to_redis))
      end
      
      def upper_rank_by_score(score)
        k = redis.zrevrangebyscore(root_key, score, :'-inf', :limit => [0, 1])
        n = redis.zcard(root_key)
        if k.empty? 
          n
        else
          redis.zrevrank(root_key, k[0])
        end
      end

      def incr(value, delta)
        redis.zincrby(root_key, delta, value.to_redis)
      end

      def first_value
        r = range_by_rank(0, 0)
        return r.empty? ? nil : r[0]
      end

      def last_value
        r = range_by_revrank(0, 0)
        return r.empty? ? nil : r[0]
      end

      def first
        pair(self.first_value)
      end

      def last
        pair(self.last_value)
      end

      def first_score
        self.score_if_exist(self.first_value)
      end

      def last_score
        self.score_if_exist(self.last_value)
      end

      private
      def pair(v)
        if v
          [self.score(v), v]
        end
      end
    end

    #
    # ストア
    #
    class ModelStore
      def self.inherited(subclass)
        subclass.class_eval <<-RUBY
        def self.klass
          "#{subclass.name.split('::')[-2]}"
        end
        def self.klass_snakecase
          "#{subclass.name.split('::')[-2].snakecase}"
        end
        RUBY
      end

      def initialize(id)
        raise "id must be Integer: passed = #{id.inspect}" unless
          id.kind_of?(Integer)
        raise "id must not == 0" if id == 0
        @prefix = "#{self.class.klass_snakecase}:id:#{id}:"
        @id = id
      end
      attr_reader :id

      def property_key(name)
        "#{@prefix}#{name}"
      end

      def read_property(k, restriction)
        restriction.from_redis(self.class.redis.get(property_key(k)))
      end

      def write_property(k, v, restriction)
        raise "type mismatch: #{v.inspect} for #{restriction.name}" unless
          restriction.contains?(v)
        self.class.redis.set(property_key(k), v.to_redis)
      end

      def write_property_nx(k, v, restriction)
        raise "type mismatch: #{v.inspect} for #{restriction.name}" unless
          restriction.contains?(v)
        self.class.redis.setnx(property_key(k), v.to_redis)
      end

      def restriction(k)
        self.__send__("#{s}_restriction")
      end

      def mget(*symbols)
        values = redis.mget(symbols.map { |s| property_key(s) })
        symbols.zip(values).map do |s, v|
          restriction(s).from_redis(v)
        end
      end

      def mset(*params)
        raise "mset params count must be even" unless params.length % 2 == 0

        a = []
        params.each_slice(2) do |k, v|
          raise "type mismatch: #{v.inspect} for #{restriction.name}" unless
            restriction.contains?(v)
          a.push k
          a.push v.to_redis
        end
        redis.mset(*a)
      end
    end
    
    #
    # 本体実装
    #
    def initialize(store)
      store.kind_of?(ModelStore) or
        raise "don't call constructor directly: use 'attach'" 
      @store = store
    end

    attr_reader :store

    def ==(other)
      store.id == other.store.id
    end

    def self.contains?(v)
      v.kind_of?(self) || v.kind_of?(Integer)
    end

    def self.from_redis(s)
      self.attach_if_exist(s.to_i)
    end

    def to_redis
      self.store.id
    end

    def now
      Time.at(redis.time[0])
    end

    def self.inherited(subclass)
      subclass.class_eval <<-RUBY
      class #{subclass.lastname}Store < self.superclass.store_class
      end
      def self.store_class
        #{subclass.lastname}Store
      end
      def self.id_seed_key
        "id_seed"
      end
      def self.new_instance(&block)
        self.attach(redis.incr self.id_seed_key).tap do |o|
          if block_given?
            yield o
          end
        end
      end
      RUBY
    end

    def self.klass
      self.name.split('::').last
    end

    def self.klass_snakecase
      self.klass.snakecase
    end
    
    def self.property(name, restriction)
      self.class_eval <<-RUBY
      class #{klass}Store < self.superclass.store_class
        def #{name}
          read_property("#{name}", #{restriction})
        end
        
        def #{name}=(val)
          write_property("#{name}", val, #{restriction})
        end

        def #{name}_key
          property_key("#{name}")
        end

        def #{name}_incr(val)
          redis.incrby(#{name}_key, val)
        end

        def #{name}_write(s)
          self.class.redis.set(#{name}_key, s.to_redis)
        end

        def #{name}_restriction
          #{restriction}
        end
      end
      RUBY
    end

    def self.cooked_property(property_class, name, key_restriction, value_restriction)
      key_restriction ||= "nil"
      value_restriction ||= "nil"
      self.class_eval <<-RUBY
      class #{klass}Store < self.superclass.store_class
        def #{name}
          @#{name} ||= #{property_class}.new(redis, #{name}_key, #{key_restriction}, #{value_restriction})
        end

        def #{name}_key
          property_key("#{name}")
        end
      end
      RUBY
    end

    def self.dictionary_property(name, key_restriction, value_restriction)
      cooked_property(ModelDictionary, name, key_restriction, value_restriction)
    end
    
    def self.list_property(name, restriction)
      cooked_property(ModelList, name, nil, restriction)
    end
    
    def self.array_property(name, restriction)
      cooked_property(ModelArray, name, nil, restriction)
    end

    def self.set_property(name, restriction)
      cooked_property(ModelSet, name, nil, restriction)
    end
      
    def self.ordered_set_property(name, restriction)
      cooked_property(ModelOrderedSet, name, nil, restriction)
    end
      
    def self.score_map_property(name, restriction)
      cooked_property(ModelScoreMap, name, restriction, Integer)
    end
    
    def self._attach(id)
      self.new(self.store_class.new(id))
    end

    def self.attach(id)
      self.new(self.store_class.new(id))
    end

    def self.attach_if_exist(id)
      id && id != 0 ? self.attach(id) : nil
    end

    def self.cache_property(*names)
      names.each do |name|
        self.class_eval <<-RUBY
      def #{name}
        @#{name} ||= self.store.#{name}
      end
RUBY
      end
    end

    def self.make_index(key, value)
      self.redis.setnx("#{klass_snakecase}:#{key}:#{value}", 0) or return nil

      yield.tap do |obj|
        redis.set("#{klass_snakecase}:#{key}:#{value}", obj.store.id)
      end
    end

    def self.index_accessor(key)
      self.class_eval <<-RUBY
      class #{klass}Store < self.superclass.store_class
        def self.find_by_#{key}(value)
          found_id = redis.get("#{klass_snakecase}:#{key}:" + value)
          if found_id && found_id != '0'
            #{self.name}.attach(found_id.to_i)
          end
        end
      end
      RUBY
    end

    def self.store_class
      ModelStore
    end

    def self.redis
      self.store_class.redis
    end

    def self.set_redis(r)
      self.store_class.set_redis(r)
    end

    def id
      raise "use self.store.id insted of self.id"
    end

    def redis
      self.class.redis
    end

    def klass
      self.class.klass
    end

    def klass_snakecase
      self.class.klass_snakecase
    end
  end

  class PlatformModel < Model
    class PlatformModelStore < ModelStore
      def self.redis
        @@redis
      end

      def redis
        @@redis
      end

      def self.set_redis(r)
        @@redis = r
      end
    end
  end

  class GameModel < Model
    class GameModelStore < ModelStore
      def self.redis
        @@redis
      end

      def redis
        @@redis
      end

      def self.set_redis(r)
        @@redis = r
      end
    end
  end
  
end

