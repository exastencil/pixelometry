def define_attribute(identifier, &block)
  Game.class_variable_get(:@@attributes)[identifier] = block
  Entity.define_method "#{identifier}?".to_sym do
    @attributes.include? identifier
  end
end
