# -*- coding: utf-8 -*-

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

def tuple_template(*args) TupleTemplate.new(args) end
def record_template(*args) RecordTemplate.new(*args) end

class Nullable
  def initialize(arg)
    @arg = arg
  end

  attr_reader :arg
end

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

class CookedParams
  def initialize(params)
    @params = params
  end

  def method_missing(action, *args)
    p = @params[action]
    if p != nil
      p
    else
      super
    end
  end
end

class Hash
  def enstructure(validator)
    r = {}
    validator.each do |k, v|
      av = self[k] or raise StructureException, "paramerter '#{k}' is not exist"
      if v[0]
        v[0].match(av) && $& == av or
          raise StructureException, "bad #{k}" # 完全一致
      end
      r[k] = v[1].from_s(av)
    end
    CookedParams.new(r)
  end
end
