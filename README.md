# Progressive Mouse System
By default, RPG Maker VX Ace does not allow you to use the mouse. When I looked for scripts online, I was disappointed by the lack of decent mouse scripts available. This script is a rewrite of [Basic Mouse System v2.7h](https://forums.rpgmakerweb.com/index.php?threads/basic-mouse-system-addons.1752), which had the right idea but was messy to work with. I figured I might as well release this for you to use.

This system allows you to script the mouse yourself. The following functionality is built-in:
- LMB to use menu buttons
- LMB to move to tile
- LMB to activate events from afar
- RMB to open menu / go back in menu

The mouse cursors are edited from Pixel Perfect and Freepik and are free to use if you credit them.

*The script assumes you have [Yanfly Ace Core Engine](https://github.com/Archeia/YEARepo/blob/master/Core/Ace_Core_Engine.rb) and [Yanfly Ace Message System](https://github.com/Archeia/YEARepo/blob/master/Core/Ace_Message_System.rb). If you don't have them, you will need to edit line 312.*

## Documentation

Script calls:

    x, y = $mouse.get_mouse_pos
      Returns the mouse position from the OS
    
    x, y = $mouse.get_mouse_pos_passive
      Returns the rendered mouse position (updates every frame)
    
    is_within = $mouse.mouse_within_rect?(rect)
      Returns true if the mouse is within the rect
    
    is_down = $mouse.left_button_down?(allow_repeat = false)
    is_down = $mouse.right_button_down?(allow_repeat = false)
    is_down = $mouse.middle_button_down?(allow_repeat = false)
      Returns true if the mouse button is down
      If allow_repeat is false then the method will only return true once
      until the mouse button is unpressed
    
    is_disabled = $mouse.disabled?
      Returns true if the mouse is not currently active
    
    $mouse.set_mouse_enabled(enabled = !@is_enabled)
      Toggles the mouse
    
Event names:
  
    Put these codes in the name of an event:
      T:# - event can be triggered from afar by mouse click, # is the maximum
            number of tiles distance
      I:# - where # is the icon index to change the cursor to on hover
      
      Example: Character I:262 T:5
