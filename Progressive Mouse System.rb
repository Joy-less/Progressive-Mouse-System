#==============================================================================
# ** Progressive Mouse System                                      (2022-04-12)
#    by Joyless
#    based on Basic Mouse System v2.7h by V.M of D.T
#------------------------------------------------------------------------------
#  Allows control of the game using the mouse as well as the keyboard.
#  
#  Script calls:
#    x, y = $mouse.get_mouse_pos
#      Returns the mouse position from the OS
#    
#    x, y = $mouse.get_mouse_pos_passive
#      Returns the rendered mouse position (updates every frame)
#    
#    is_within = $mouse.mouse_within_rect?(rect)
#      Returns true if the mouse is within the rect
#    
#    is_down = $mouse.left_button_down?(allow_repeat = false)
#    is_down = $mouse.right_button_down?(allow_repeat = false)
#    is_down = $mouse.middle_button_down?(allow_repeat = false)
#      Returns true if the mouse button is down
#      If allow_repeat is false then the method will only return true once
#      until the mouse button is unpressed
#    
#    is_disabled = $mouse.disabled?
#      Returns true if the mouse is not currently active
#    
#    $mouse.set_mouse_enabled(enabled = !@is_enabled)
#      Toggles the mouse
#    
#  Event names:
#    Put these codes in the name of an event:
#      T:# - event can be triggered from afar by mouse click, # is the maximum
#            number of tiles distance
#      I:# - where # is the icon index to change the cursor to on hover
#      
#      Example: Character I:262 T:5
#==============================================================================

MOUSE_ICON = 528                                 # The number of the mouse icon
MOUSE_ICON_OFFSET = {                     # Mouse offset in pixels of each icon
  true => [0, 0],                           # true is for all unspecified icons
  529 => [-8, 0],
}
MOUSE_KEEP_WITHIN_WINDOW = true        # Lock the rendered cursor in the window
MOUSE_CLICK_MUST_BE_WITHIN_BUTTON = true    # Only accept clicks within buttons
MOUSE_FADE_ENABLED = true                        # Mouse fades away if not used
MOUSE_FRAMES_BEFORE_FADE = 600               # Frames of inactivity before fade
MOUSE_FADE_DURATION_FRAMES = 60                          # Fade duration frames

class Mouse
  # Win32 API calls
  CPOS = Win32API.new 'user32', 'GetCursorPos', ['p'], 'v'
  WINX = Win32API.new 'user32', 'FindWindowEx', ['l','l','p','p'], 'i'
  ASKS = Win32API.new 'user32', 'GetAsyncKeyState', ['p'], 'i'
  SMET = Win32API.new 'user32', 'GetSystemMetrics', ['i'], 'i'
  WREC = Win32API.new 'user32', 'GetWindowRect', ['l','p'], 'v'
  SHOWMOUSE = Win32API.new 'user32', 'ShowCursor', 'i', 'i'
  
  
  def draw_mouse_icon(icon = @mouse_icon, bitmap = @mouse_sprite.bitmap)
    if icon != @temporary_icon then
      @temporary_icon = icon
      
      bitmap.clear
      icon_bitmap = Cache.system("Iconset")
      rect = Rect.new(icon % 16 * 24, icon / 16 * 24, 24, 24)
      bitmap.blt(0, 0, icon_bitmap, rect)
    end
  end
  
  def get_mouse_pos
    rect = '0000000000000000'
    cursor_pos = '00000000'
    WREC.call(@window_loc, rect)
    side, top = rect.unpack("ll")
    CPOS.call(cursor_pos)
    
    mouse_x, mouse_y = cursor_pos.unpack("ll")
    w_x = side + SMET.call(5) + SMET.call(45)
    w_y = top + SMET.call(6) + SMET.call(46) + SMET.call(4)
    mouse_x -= w_x; mouse_y -= w_y
    
    if @keep_within_window
      mouse_x = [[mouse_x, 0].max, Graphics.width - 5].min
      mouse_y = [[mouse_y, 0].max, Graphics.height - 5].min
    end
    
    return mouse_x, mouse_y
  end
  
  def get_mouse_pos_passive
    return @mouse_pos_x, @mouse_pos_y
  end
  
  def mouse_within_rect?(rect)
    mouse_x, mouse_y = $mouse.get_mouse_pos_passive
    if mouse_x >= rect.x and mouse_x < rect.x + rect.width then
      if mouse_y >= rect.y and mouse_y < rect.y + rect.height then
        return true
      end
    end
    return false
  end
  
  def left_button_down?(allow_repeat = false)
    @lmb_is_pressed = ASKS.call(@lmb) != 0
    
    if allow_repeat == false then
      # Remove the cooldown if mouse is not pressed
      @lmb_cooldown = nil if @lmb_is_pressed == false
      # Return false if the mouse has been pressed already without unpressing
      return false if @lmb_cooldown == true
      # Activate the cooldown when pressed
      @lmb_cooldown = true if @lmb_is_pressed == true
    end
    
    return @lmb_is_pressed
  end
  
  def right_button_down?(allow_repeat = false)
    @rmb_is_pressed = ASKS.call(@rmb) != 0
    
    if allow_repeat == false then
      # Remove the cooldown if mouse is not pressed
      @rmb_cooldown = nil if @rmb_is_pressed == false
      # Return false if the mouse has been pressed already without unpressing
      return false if @rmb_cooldown == true
      # Activate the cooldown when pressed
      @rmb_cooldown = true if @rmb_is_pressed == true
    end
    
    return @rmb_is_pressed
  end
  
  def middle_button_down?(allow_repeat = false)
    @mmb_is_pressed = ASKS.call(0x04) != 0
    
    if allow_repeat == false then
      # Remove the cooldown if mouse is not pressed
      @mmb_cooldown = nil if @mmb_is_pressed == false
      # Return false if the mouse has been pressed already without unpressing
      return false if @mmb_cooldown == true
      # Activate the cooldown when pressed
      @mmb_cooldown = true if @mmb_is_pressed == true
    end
    
    return @mmb_is_pressed
  end
  
  def disabled?
    return (@is_enabled == false or @mouse_sprite.opacity <= 0)
  end
  
  def set_mouse_enabled(enabled = !@is_enabled)
    @is_enabled = enabled
  end

  
  def update_transparency
    if @is_enabled == false then
      @mouse_sprite.opacity = 0
      
    elsif MOUSE_FADE_ENABLED == true then
      if @moved_mouse == true then
        @transparency = 0
      else
        @transparency += 1
      end
      if @transparency > MOUSE_FRAMES_BEFORE_FADE then
        @transparency = MOUSE_FRAMES_BEFORE_FADE + MOUSE_FADE_DURATION_FRAMES if @transparency > MOUSE_FRAMES_BEFORE_FADE + MOUSE_FADE_DURATION_FRAMES
        @transparency_original_bitmap = @mouse_sprite.bitmap if !@transparency_original_bitmap
        
        @mouse_sprite.bitmap = @transparency_original_bitmap
        
        @mouse_sprite.opacity = 255 - (@transparency.to_f - MOUSE_FRAMES_BEFORE_FADE) / MOUSE_FADE_DURATION_FRAMES * 255
      else
        @mouse_sprite.opacity = 255
      end
    end
  end
  
  def update_mouse_icon
    mouse_pos_x, mouse_pos_y = $mouse.get_mouse_pos_passive
    
    x = ($game_map.display_x + mouse_pos_x.to_f / 32).to_i
    y = ($game_map.display_y + mouse_pos_y.to_f / 32).to_i
    
    return if x == @last_mouse_x and y == @last_mouse_y
    @last_mouse_x, @last_mouse_y = x, y
    
    events = $game_map.events_xy(x, y)
    events.each do |event|
      event_mouse_icon = event.get_mouse_icon
      if event_mouse_icon then
        $mouse.draw_mouse_icon(event_mouse_icon)
        return
      end
    end
    $mouse.draw_mouse_icon # Reset mouse icon
  end
  
  def update_mouse_position
    @mouse_sprite.x, @mouse_sprite.y = @mouse_pos_x, @mouse_pos_y
    
    mouse_icon_offset = MOUSE_ICON_OFFSET[@temporary_icon]
    if !mouse_icon_offset then
      mouse_icon_offset = MOUSE_ICON_OFFSET[true]
    end
    @mouse_sprite.x += mouse_icon_offset[0]
    @mouse_sprite.y += mouse_icon_offset[1]
  end
  
  def update
    # Get the mouse position
    new_pos_x, new_pos_y = get_mouse_pos
    # Store whether the mouse moved this frame
    @moved_mouse = new_pos_x != @mouse_pos_x or new_pos_y != @mouse_pos_y
    # Store the mouse position
    @mouse_pos_x, @mouse_pos_y = new_pos_x, new_pos_y
    # Update mouse icon if over event
    update_mouse_icon
    # Render the mouse position
    update_mouse_position
    # Update fade out transparency (if mouse does not move)
    update_transparency
  end
  
  def reinitialize_if_disposed
    if @mouse_sprite.disposed?
      initialize
    end
  end
  
  def initialize(mouse_icon = MOUSE_ICON, keep_within_window = MOUSE_KEEP_WITHIN_WINDOW)
    # Set class instance variables
    @mouse_icon = mouse_icon
    @keep_within_window = keep_within_window
    
    @window_loc = WINX.call(0, 0, "RGSS PLAYER", 0)
    
    mouse_button_order = true if SMET.call(23) != 0
    mouse_button_order ? @lmb = 0x02 : @lmb = 0x01
    mouse_button_order ? @rmb = 0x01 : @rmb = 0x02
    
    @mouse_pos_x = 0
    @mouse_pos_y = 0
    
    @transparency = 0
    
    @temporary_icon = nil
    
    @is_enabled = true
    
    # Hide the real mouse cursor
    SHOWMOUSE.call(0)
    
    # Create the mouse sprite
    @mouse_sprite = Sprite.new
    @mouse_sprite.bitmap = Bitmap.new(24, 24)
    
    # Draw the mouse icon
    draw_mouse_icon
    
    # Set the initial mouse position
    @mouse_sprite.x = 50
    @mouse_sprite.y = 50
    @mouse_sprite.z = 1_000_000
  end
end

class Window_Selectable
  alias mouse_update update
  def update
    mouse_update
    update_mouse if self.active
  end
  def update_mouse
    return if $mouse.disabled?
    item_max.times do |i|
      # Get the item position
      rect = item_rect(i)
      rect_offset_x, rect_offset_y = self.x + standard_padding - self.ox, self.y + standard_padding - self.oy
      rect_x, rect_y = rect.x + rect_offset_x, rect.y + rect_offset_y
      
      # Check whether the mouse is within the item bounds
      mouse_within_item = $mouse.mouse_within_rect?(
        Rect.new(rect_x, rect_y, rect.width, rect.height))
      
      self.index = i if mouse_within_item
      
      if MOUSE_CLICK_MUST_BE_WITHIN_BUTTON and mouse_within_item then
        process_ok if $mouse.left_button_down? and ok_enabled?
      end
    end
    process_cancel if $mouse.right_button_down? and cancel_enabled?
    $mouse.right_button_down?
    $mouse.left_button_down?
  end
end

class Window_NameInput
  alias mouse_process_handling process_handling
  def process_handling
    mouse_process_handling
    process_back if !$mouse.disabled? and $mouse.right_button_down?
  end
  def item_max
    return 90
  end
end
 
class Window_Message < Window_Base
  def input_pause
    self.pause = true
    wait(10)
    Fiber.yield until Input.trigger?(:B) || Input.trigger?(:C) ||
      (!$mouse.disabled? and $mouse.left_button_down?) ||
      (defined?(YEA::MESSAGE::TEXT_SKIP) && Input.press?(YEA::MESSAGE::TEXT_SKIP))
    Input.update
    self.pause = false
  end
end

class Scene_File < Scene_MenuBase
  alias mouse_update update
  def update
    mouse_update
    mouse_input
  end
  def mouse_input
    return if $mouse.disabled?
    
    last_index = @index # For checking if the index has changed
    @scroll = self.top_index # Get the top save file in the scrolling window
    
    if @savefile_windows.length < visible_max then
      @scroll += visible_max - @savefile_windows.length
    end
    
    @savefile_windows.length.times do |n|
      window = @savefile_windows[n]
      button_rect = Rect.new(window.x, @help_window.height + window.y - (window.height * self.top_index), window.width, window.height)
      
      if $mouse.mouse_within_rect?(button_rect) then
        @index = n
        
        if @index != last_index then
          Sound.play_cursor
          @savefile_windows[last_index].selected = false
          @savefile_windows[@index].selected = true
        end
        on_savefile_ok if $mouse.left_button_down?
      end
    end
    $mouse.left_button_down?
    on_savefile_cancel if $mouse.right_button_down?
  end
end

class Scene_Gameover
  alias mouse_update update
  def update
    mouse_update
    goto_title if !$mouse.disabled? and ($mouse.left_button_down? or $mouse.right_button_down?)
  end
end

class Window_NumberInput
  Button_Width = 20 # The width of each button
  Button_Height = 24 # The height of each button
  Button_Padding = 12 # The padding at the top left corner (width and height)
  
  alias mouse_update update
  def update
    mouse_update
    mouse_input if SceneManager.scene_is?(Scene_Map) and self.active
  end
  def mouse_input
    button_x = self.x + Button_Padding
    button_y = self.y + Button_Padding
    
    (@digits_max + 1).times do |n|
      # Get each button's coordinates
      current_button_rect = Rect.new(button_x + (Button_Width * n), button_y, Button_Width, Button_Height)
      
      # If the mouse is within the button
      if $mouse.mouse_within_rect?(current_button_rect) then
        @index = n
        
        if n == @digits_max then
          # OK button
          self.process_ok if $mouse.left_button_down?
        else
          # Digit button
          process_mouse_change
        end
        break
      end
    end
    self.process_cancel if $mouse.right_button_down?
  end
  def refresh
    contents.clear
    change_color(normal_color)
    s = sprintf("%0*d", @digits_max, @number)
    @digits_max.times do |i|
      rect = item_rect(i)
      rect.x += 1
      draw_text(rect, s[i,1], 1)
    end
    # Add an "OK" button
    ok_rect = item_rect(@digits_max)
    ok_rect.x += 1
    draw_text(ok_rect, "OK", 1)
  end
  def update_placement
    # Increase the window width to add an OK button
    self.width = (@digits_max + 1) * 20 + padding * 2
    self.height = fitting_height(1)
    self.x = (Graphics.width - width) / 2
    if @message_window.y >= Graphics.height / 2
      self.y = @message_window.y - height - 8
    else
      self.y = @message_window.y + @message_window.height + 8
    end
  end
  def process_mouse_change
    return unless active
    # Get the number to change based on the digit
    number_change = 10 ** (@digits_max - 1 - @index)
    # LMB: + 1 | RMB: - 1
    if $mouse.left_button_down? then
      @number += number_change 
      Sound.play_cursor
    elsif $mouse.right_button_down? then
      @number -= number_change 
      Sound.play_cursor
    end
    # Redraw the buttons
    refresh
  end
end

class Game_Player < Game_Character
  alias mouse_move_update update
  def update
    mouse_move_update
    mouse_input
  end
  def mouse_input
    return if !movable? || $game_map.interpreter.running?
    return if moving?
    return if !$mouse.left_button_down?(true)
    
    mouse_pos_x, mouse_pos_y = $mouse.get_mouse_pos_passive
    
    x = ($game_map.display_x + mouse_pos_x.to_f / 32).to_i
    y = ($game_map.display_y + mouse_pos_y.to_f / 32).to_i
    
    return if trigger_event_from_afar(x, y, [0,1,2], false)
    
    x -= @x
    y -= @y
    
    if x != 0 or y != 0 then # Mouse is not at player
      move_straight(2) if x == 0 and y > 0 # Down
      move_straight(4) if x < 0 and y == 0 # Left
      move_straight(6) if x > 0 and y == 0 # Right
      move_straight(8) if x == 0 and y < 0 # Up
      move_diagonal(4, 2) if x < 0 and y > 0 # Down Left
      move_diagonal(6, 2) if x > 0 and y > 0 # Down Right
      move_diagonal(4, 8) if x < 0 and y < 0 # Up Left
      move_diagonal(6, 8) if x > 0 and y < 0 # Up Right
    end
  end
  def magnitude(x, y)
    # Pythagoras' theorem
    return (Math.sqrt(x.to_f ** 2 + y.to_f ** 2)).floor
  end
  def trigger_event_from_afar(x, y, triggers, normal)
    return false if $game_map.interpreter.running?
    $game_map.events_xy(x, y).each do |event|
      # If event is close enough to trigger
      activation_distance = event.get_trigger_from_afar_distance
      next unless activation_distance and magnitude(x - @x, y - @y) <= activation_distance
      # If event is triggered by action button, player touch or event touch
      if event.trigger_in?(triggers)
        event.start
        return true
      end
    end
    return false
  end
end

class Game_Event
  def get_trigger_from_afar_distance
    return @event.name.downcase =~ /t:(\d+)/ ? $1.to_i : false
  end
  def get_mouse_icon
    return @event.name.downcase =~ /i:(\d+)/ ? $1.to_i : false
  end
end

class Scene_Map
  alias mouse_update update
  def update
    mouse_update
    mouse_input_events
  end
  def mouse_input_events
    call_menu if $mouse.right_button_down? and !$game_map.interpreter.running?
  end
end

class Scene_Base
  # Update the cursor every frame
  alias cursor_update update_basic
  def update_basic
    cursor_update
    mouse_cursor
  end
  def mouse_cursor
    $mouse.update
  end
end

class Scene_Title < Scene_Base
  alias mouse_start start
  def start
    $mouse.reinitialize_if_disposed
    mouse_start
  end
end

$mouse = Mouse.new