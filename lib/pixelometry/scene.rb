class Scene
  # Predefined Scene templates
  @@templates = {}

  def initialize(renderer = nil, &block)
    # All entities loaded in this scene
    @entities = {}

    # Systems registered for this scene
    @systems = {}

    # The renderer to use on this scene (a `System`)
    @renderer = renderer

    # The scene custom update block
    @update_proc = proc {}

    # Which entities subscribe to which events
    # (Symbol (event_type) => Set[Integer (entity id)])
    @triggers = {}

    # Next assignable Entity index
    @assignable_entity_id = 0
    instance_exec(&block)
  end

  def create_entity(template = nil, arguments = {}, &block)
    entity = nil
    if template
      entity = Entity.from_template @assignable_entity_id, self, template
      entity.instance_exec(&block) if block_given?
    else
      raise Pixelometry::Error, 'Cannot create an entity without a template or a definition' unless block_given?

      entity = Entity.new @assignable_entity_id, self, &block
    end

    # Initialize properties that were passed as arguments
    arguments.each do |property, value|
      if entity.respond_to? property
        entity.send "#{property}=", value
      else
        raise Pixelometry::Error, "Invalid argument #{property}. No such property on entity."
      end
    end

    @entities[@assignable_entity_id] = entity
    @assignable_entity_id += 1

    entity
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
    @update_proc.call
    if @renderer
      @entities.values.select { |e| e.renderable? || e.typographical? }
               .sort { |a, b| @renderer.render_order(a, b) }
               .each { |entity| @renderer.process entity }
    end
  end

  def each_frame(&block)
    @update_proc = block
  end

  def trigger(kind, event)
    if @triggers.key? kind # any entities care?
      @triggers[kind].each do |entity_id|
        @entities[entity_id]&.trigger kind, event
      end
    end
  end

  def refresh_triggers(entity_id, triggers)
    @triggers.each do |_event_type, entity_ids|
      entity_ids -= [entity_id]
    end
    triggers.each do |event_type, _behavior|
      @triggers[event_type] ||= Set[]
      @triggers[event_type] << entity_id
    end
    @triggers = @triggers.select { |_, v| !v.empty? }
  end
end
