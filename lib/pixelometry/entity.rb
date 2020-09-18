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

  def initialize(id, &block)
    @id = id
    @properties = {}
    @behaviors = {}
    @triggers = {}
    instance_exec(&block)
  end

  def property(key, opts = {})
    # Stores the value
    @properties[key] = opts[:default]

    # Creates a reader method similar to `attr_reader key` on this object only
    define_singleton_method(key) { @properties[key] }
    # Creates a writer method similar to `attr_writer key` on this object only
    define_singleton_method("#{key}=") { |value| @properties[key] = value }
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

  def trigger(kind, event = nil)
    @triggers[kind]&.each { |b| instance_exec(event, &@behaviors[b]) }
  end

  def self.from_template(id, template)
    raise Pixelometry::Error.new "Missing entity template for #{template}" unless @@templates[template]

    new(id, &@@templates[template])
  end
end

def define_entity(template_name, &block)
  raise Pixelometry::Error, 'No block given to `define_entity`' unless block_given?

  # Run the definition once to check the syntax
  Entity.new(0, &block)

  templates = Entity.class_variable_get(:@@templates)
  templates[template_name] = block
end
