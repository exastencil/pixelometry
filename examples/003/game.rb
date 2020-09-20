require 'ruby2d'

# Ruby2D Window Configuration
set title: 'Ruby2D Input Example'

# Display instructions
label = Text.new 'Press Escape to exit', color: 'lime'
label.x = (Window.width - label.width) / 2
label.y = (Window.height - label.height) / 2

# `on` registers a block for a type of event
# `off` can be used to remove it
# Supported events are:
# - :key and its variants :key_down, :key_held and :key_up
# - :controller andits variants :controller_axis, :controller_button_down and :controller_button_up
# - :mouse and its variants :mouse_down, :mouse_up, :mouse_move and :mouse_scroll
on :key_down do |event|
  if event.key == 'escape'
    close # alias for Window.close
  else
    puts event.key # useful for seeing key codes
  end
end

show
