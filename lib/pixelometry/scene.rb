class Scene
  # Predefined Scene templates
  @@templates = {}

  def initialize(renderer = nil, &block)
    # All entities loaded in this scene
    @entities = {}

    # Systems registeredd for this scene
    @systems = {}

    # The renderer to use on this scene (a `System`)
    @renderer = renderer

    # Next assignable Entity index
    @assignable_entity_id = 0
    instance_exec(&block)
  end

  def create_entity(template = nil, arguments = {}, &block)
    entity = nil
    if template
      entity = Entity.from_template @assignable_entity_id, template
      entity.instance_exec(&block) if block_given?
    else
      raise Pixelometry::Error, 'Cannot create an entity without a template or a definition'
      entity = Entity.new @assignable_entity_id, &block
    end

    # Initialize properties that were passed as arguments
    arguments.each do |property, value|
      if entity.respond_to? property
        entity.send "#{property}=", value
      else
        raise Pixelometry::Error.new "Invalid argument #{property}. No such property on entity."
      end
    end

    @entities[@assignable_entity_id] = entity
    @assignable_entity_id += 1
  end

  def create_system(identifier = nil, _arguments = {}, &block)
    raise Pixelometry::Error, 'Cannot create a system without a definition' unless block_given?

    @systems[identifier] = block
  end

  def update
    @systems.each do |_sys, proc|
      @entities.each do |_id, entity|
        proc.call entity
      end
    end
    @entities.each { |_id, entity| @renderer.process entity } if @renderer
  end

  def trigger(kind, event)
    @entities.each do |_id, entity|
      entity.trigger kind, event
    end
  end
end
