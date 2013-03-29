# -*- coding: utf-8 -*-

require 'ostruct'

class Object
  def self.from_s(s)
    s
  end
  def self.contains?(v)
    v.kind_of?(self)
  end
end
class Integer; def self.from_s(s) s && s.to_i end end
class Symbol; def self.from_s(s) s && s.intern end end
class Time
  def self.from_s(s)
    s && Time.at(s.to_i)
  end
end

class Boolean
  def self.from_s(s)
    return nil if s.nil?
    case s
    when 'true'
      true
    when 'false'
      false
    else
      raise "bad Boolean: #{s}"
    end
  end

  def self.contains?(v)
    return v == true || v == false
  end
end

class StructureException < Exception; end

class StructureTemplate
  def initialize(args)
    @args = args
  end

  attr_reader :args
end

class TupleTemplate < StructureTemplate; end
class RecordTemplate < StructureTemplate; end
class Nullable < StructureTemplate
  def from_s(x)
    args.from_s(x)
  end
end

def tuple_template(*args) TupleTemplate.new(args) end
def record_template(*args) RecordTemplate.new(*args) end
def nullable(arg) Nullable.new(arg) end

module Structure
  def self.match(f, a)
    case f
    when Hash
      #p "hash"
      return false if a.kind_of?(Hash)
      raise StructureException, "bad hash template: #{f}" if f.length != 1
      formal_key, formal_array = f.to_a[0]
      a.each do |k, v|
        return false if !match(k, formal_key)
        return false if !match(v, formal_value)
      end
      return true
    when Array
      #p "array"
      raise StructureException, "bad array template: #{f}" if f.length != 1
      return false if !a.kind_of?(Array)
      a.each do |x|
        return false if !match(f[0], x)
      end
      return true
    when TupleTemplate
      return false if f.args.length != a.length
      f.args.each_index do |index|
        return false if !match(f.args[index], a[index])
      end
      return true
    when RecordTemplate
      return false if f.args.length != a.length
      f.args.each do |k, v|
        return false if !a.has_key?(k) || !match(v, a[k])
      end
      return true
    when Nullable
      return true if a.nil?
      return match(f.arg, a)
    when Class
      if f == Boolean
        return a == true || a == false
      else
        return a.kind_of?(f)
      end
    when Regex
      return f.match(a)
    else
      raise StructureException, "bad template: #{f}"
    end
  end
end

class Hash
  def enstructure(validator)
    r = {}
    validator.each do |key, (regex, type)|
      val = self[key]
      if (val.nil? || val=='') && !type.kind_of?(Nullable)
        raise StructureException, "paramerter '#{key}' is not exist"
      end
      if val && val != ''
        if regex
          regex.match(val) && $& == val or
            raise StructureException, "bad #{key}: #{val.inspect}" # 完全一致
        end
        r[key] = type.from_s(val)
      else
        r[key] = nil
      end
    end
    OpenStruct.new(r).freeze
  end
end
