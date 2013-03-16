# -*- coding: utf-8 -*-

class Array
  def sample
    self[rand(self.length)]
  end
end

class String
  def snakecase
    ptn = /[A-Z\s]*[^A-Z]*/
    self =~ ptn ? self.scan(ptn).map { |i|
      i.gsub(/[\s:]+/, '_').downcase
    }.join('_').gsub(/_+/,'_').sub(/_$/,'') : self
  end

  def camelcase
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map { |e| e.capitalize}.join
  end

  def ltrim(len)
    self[/.{#{len}}/] || self
  end
end

class Module
  def lastname
    self.name.split('::').last
  end

  def snakename
    self.lastname.snakecase
  end

  def camelcase
    self.lastname.camelcase
  end
end

module Enumerable
  def detect_index
    self.each_with_index do |x, i|
      if yield x
        return i
      end
    end
    nil
  end
end

module Misc

  def self.new_salt
    arr = %w(a b c d e f)
    (0..6).to_a.map{ arr[rand(6)] }.join
  end
  
  def self.hash_pw(salt, password)
    Digest::SHA1.hexdigest(salt + password)
  end

  def self.randname
    arr = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
    (0...8).to_a.map{ arr[rand(arr.length)] }.join
  end

  def self.second_to_period(sec)
    if sec < 0 then return '' end
    
    day = 0
    hour = 0
    min = 0
    if 60 <= sec then
      min, sec = sec.divmod(60);
    end
    if 60 <= min then
      hour, min = min.divmod(60);
    end
    if 24 <= hour then
      day, hour = hour.divmod(24);
    end
    r =
      (day == 0 ? '' : "#{day}日 ") +
      (hour == 0 ? '': "#{hour}時間 ") +
      (min == 0 ? '' : "#{min}分") +
      (sec == 0 ? '' : "#{sec}秒")
    return r
  end
  
  def self.range_rand(min, max)
    return min  if min == max
    min, max = [min, max].sort
    rand(max - min + 1) + min
  end
end
