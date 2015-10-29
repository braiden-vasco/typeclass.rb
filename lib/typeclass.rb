# TODO: refactoring
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity

require 'typeclass/version'

##
# Haskell type classes in Ruby.
#
class Typeclass < Module
  attr_reader :params, :instances

  TYPES = [Class, Module]
  BASE_CLASS = Object

  Instance = Struct.new(:params, :module) do
    def transmit(name, *args)
      self.module.send name, *args
    end

    def implements?(name)
      self.module.singleton_methods.include? name
    end
  end

  Params = Struct.new(:data) do
    def >(other)
      data.any? do |name, type|
        other_type = other.data[name]
        other_type.ancestors.include? type if type != other_type
      end
    end

    def collision?(other)
      self > other && other > self
    end
  end

  def initialize(params, &block)
    fail LocalJumpError, 'no block given' unless block_given?
    fail TypeError unless params.is_a? Hash
    fail ArgumentError if params.empty?

    @params = params.each do |name, type|
      name.is_a? Symbol or
        fail TypeError, 'parameter name is not a Symbol'
      fail TypeError unless Typeclass.type? type
    end

    @instances = []

    instance_exec(&block)
  end

  def fn(name, sig, &block)
    name = name.to_sym rescue (raise NameError)
    fail NameError if method_defined? name
    fail TypeError unless sig.is_a? Array
    fail TypeError unless sig.all? { |item| item.is_a? Symbol }

    typeclass = self

    f = lambda do |*args|
      fail ArgumentError if sig.length != args.count

      instance = typeclass.instance sig, args

      fail NotImplementedError unless instance

      if instance.implements? name
        instance.transmit name, *args
      elsif block
        block.call(*args)
      else
        fail NoMethodError
      end
    end

    begin
      define_singleton_method name, &f
      define_method name, &f
    rescue
      raise NameError
    end
  end

  def instance(sig, args)
    instances.each do |instance|
      return instance if sig.each_with_index.all? do |key, i|
        args[i].is_a? instance.params.data[key]
      end
    end

    nil
  end

  def self.instance(typeclass, params, &block)
    fail LocalJumpError, 'no block given' unless block_given?
    fail TypeError unless typeclass.is_a? Typeclass
    fail TypeError unless params.is_a? Hash
    fail ArgumentError unless (typeclass.params.keys - params.keys).empty?
    fail ArgumentError unless (params.keys - typeclass.params.keys).empty?

    fail TypeError unless params.all? do |name, type|
      (type.ancestors + [BASE_CLASS]).include? typeclass.params[name]
    end

    params = Params.new(params)
    index = get_index(typeclass, params)

    mod = Module.new
    mod.include typeclass
    mod.instance_exec(&block)

    instance = Instance.new(params, mod)
    typeclass.instances.insert index, instance

    instance
  end

  def self.type?(object)
    TYPES.any? { |type| object.is_a? type }
  end

  def self.get_index(typeclass, new_params)
    index = nil

    (0..typeclass.instances.count).each do |i|
      instance = typeclass.instances[i]

      if instance.nil?
        index = i if index.nil?
        break
      end

      current_params = instance.params

      fail TypeError if current_params.collision? new_params

      if index.nil? && current_params > new_params
        index = i
        break
      end
    end

    index
  end
end
