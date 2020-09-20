require 'ruby2d'

# Ruby2D Window Configuration
set title: 'Ruby2D Text Example'

# Creating elements (calling new) will assign it to be drawn
label = Text.new 'Hello World!', color: 'lime'

# But we can modify it and those changes will be applied
label.x = (Window.width - label.width) / 2
label.y = (Window.height - label.height) / 2

show
