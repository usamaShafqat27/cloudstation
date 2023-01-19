module RedisModel
  extend ActiveSupport::Concern

  included do |base|
    base.const_set :DOWNCASED_NAME, name.downcase
    base.const_set :ID_KEY, "#{base::DOWNCASED_NAME}:id"
    base.const_set :DOWNCASED_PLURAL_NAME, base::DOWNCASED_NAME.pluralize

    @primary_id = :id
    @redis_attrs = []
    @set_only = false
    @has_stream = false
    $redis.set(base::ID_KEY, 0) unless $redis.get(base::ID_KEY)
  end

  def initialize(**attrs)
    attrs.symbolize_keys!

    attrs.each do |attr, value|
      self.public_send("#{attr}=", value) if self.class.instance_variable_get(:@redis_attrs).include?(attr)
    end
  end

  def to_s
    id
  end

  def save
    attrs = {}
    self.class.instance_variable_get(:@redis_attrs).each do |attr|
      attrs[attr] = public_send(attr)
    end
    if self.valid?
      saved = self.class.create(**attrs)
      self.id ||= saved.id
    end
  end

  def stream
    self.class.stream self.id
  end

  def persisted?
    @persisted
  end

  def add_stream fields
    self.class.add_stream self.id, fields
  end

  class_methods do
    def has_stream bool
      self.instance_variable_set(:@has_stream, bool)
    end

    def stream id
      $redis.xrange "#{self::DOWNCASED_NAME}:stream:#{id}"
    end

    def add_stream id, fields
      $redis.xadd "#{self::DOWNCASED_NAME}:stream:#{id}", fields
    end

    def redis_attrs *attrs
      self.instance_variable_set(:@redis_attrs, [*attrs, :id])
      self.attr_accessor *self.instance_variable_get(:@redis_attrs)
    end

    def set_only bool
      self.instance_variable_set(:@set_only, bool)
    end

    def redis_idx(*args)
      $redis.call('FT.CREATE', "idx:#{self::DOWNCASED_PLURAL_NAME}", 'ON', 'HASH', 'PREFIX', '1', self::DOWNCASED_NAME, 'SCHEMA', *args)
    end

    def primary_id id
      self.instance_variable_set(:@primary_id, id)
    end

    def find(id)
      value = $redis.hgetall("#{self::DOWNCASED_NAME}:#{id}")
      if value.present?
        instance = self.new(**value)
        instance.instance_variable_set(:@persisted, true)
        instance
      else
        nil
      end
    end

    def exists?(id)
      $redis.sismember(self::DOWNCASED_PLURAL_NAME, id)
    end

    def debug
      byebug
    end

    def puts_redis_attrs
      puts self.instance_variable_get(:@redis_attrs)
    end

    def create(**attrs)
      attrs.symbolize_keys!
      attrs.slice!(*self.instance_variable_get(:@redis_attrs))

      id_suffix = attrs[self.instance_variable_get(:@primary_id)] || $redis.incr(id)
      id = "#{self::DOWNCASED_NAME}:#{id_suffix}"

      $redis.hset(id, {**attrs, id: id_suffix}) unless self.instance_variable_get(:@set_only)

      $redis.sadd(self::DOWNCASED_PLURAL_NAME, id_suffix)

      self.new(**attrs, id: id_suffix)
    end

    def find_all(*ids)
      if ids.present?
        $redis.pipelined do
          ids.each {|id| $redis.hgetall "#{self::DOWNCASED_NAME}:#{id}"}
        end.map!{|obj|
          self.new(**obj)
        }
      else
        []
      end
    end

    def all
      members = $redis.smembers self::DOWNCASED_PLURAL_NAME
      return members if self.instance_variable_get(:@set_only)

      find_all *members
    end
  end
end
