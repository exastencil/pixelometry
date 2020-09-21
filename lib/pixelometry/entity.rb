require 'set'

# Entity Class
#
# The `Entity` class stores the entity definitions, while instances of `Entity`
# are embedded in `Scene`s.
#
# Entities are defined using `define_entity :template` and instantiated using
# `create_entity :template` or by passing a block to `create_entity`.
#
class Entity
  # Internal storage of entity templates
  @@templates = {}

  def initialize(id, scene, &block)
    @id = id
    @scene = scene
    @properties = {}
    @attributes = Set[]
    @behaviors = {}
    @triggers = {}
    instance_exec(&block)
  end

  def inspect
    "#<Entity:#{@id} attributes: #{@attributes}, properties: #{@properties}>"
  end

  def to_s
    inspect
  end

  def property(key, opts = {})
    # Stores the value
    @properties[key] = opts[:default]

    # Creates a reader method similar to `attr_reader key` on this object only
    define_singleton_method(key) { @properties[key] }
    # Creates a writer method similar to `attr_writer key` on this object only
    define_singleton_method("#{key}=") { |value| @properties[key] = value }
  end

  def attribute(identifier, opts = {})
    templates = Game.class_variable_get(:@@attributes)
    unless templates.key? identifier
      raise Pixelometry::Error.new "Undefined attribute `#{identifier}`: Have you defined and required it, or perhaps misspelled it?"
    end

    instance_exec opts, &templates[identifier]
    @attributes.add identifier
  end

  def behavior(identifier, opts = {}, &block)
    identifier = identifier.to_sym
    @behaviors[identifier] = block

    if opts[:on]
      triggers = @triggers[opts[:on]] || []
      triggers << identifier
      @triggers[opts[:on]] = triggers
    end
  end

  def on(kind, &block)
    @triggers[kind] ||= []
    @triggers[kind] << block
  end

  def trigger(kind, event = nil)
    @triggers[kind]&.each do |proc_or_behavior_key|
      if proc_or_behavior_key.is_a? Proc
        instance_exec(event, &proc_or_behavior_key)
      else
        instance_exec(event, &@behaviors[proc_or_behavior_key])
      end
    end
  end

  def emit(kind, event = nil)
    @scene.trigger kind, event
  end

  def self.from_template(id, scene, template)
    unless @@templates[template]
      raise Pixelometry::Error, "Missing entity template for #{template}. Templates: #{@@templates.keys}"
    end

    new(id, scene, &@@templates[template])
  end
end

def define_entity(template_name, &block)
  raise Pixelometry::Error, 'No block given to `define_entity`' unless block_given?

  # Run the definition once to check the syntax
  Entity.new(0, nil, &block)

  templates = Entity.class_variable_get(:@@templates)
  templates[template_name] = block
end
