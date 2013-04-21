# -*- coding: utf-8 -*-

require 'rubygems'
require 'redis'
require 'hiredis'
require 'digest'
require "#{File.dirname(__FILE__)}/../server/redis_mapper.rb"
require "#{File.dirname(__FILE__)}/../server/domain_models.rb"

RedisMapper::PlatformModel.set_redis(Redis.new)
def redis
  RedisMapper::PlatformModel.redis
end
  
redis.flushdb

World.singleton



