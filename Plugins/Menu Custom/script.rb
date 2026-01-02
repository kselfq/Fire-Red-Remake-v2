#===============================================================================
# Ensure pbBlurMap is defined and control its blur strength
#===============================================================================
unless Kernel.respond_to?(:pbBlurMap)
  def pbBlurMap(bitmap)
    if bitmap.is_a?(Bitmap)
      bitmap.blur; bitmap.blur; bitmap.blur; bitmap.blur 
      bitmap.blur; bitmap.blur; bitmap.blur; bitmap.blur 	
    end
    return bitmap
  end
end
#===============================================================================

class Scene_Map
  alias :original_call_menu :call_menu
  def call_menu
    $game_temp.menu_calling = false
    $game_player.straighten
    $game_map.update
    pbCallMenu2
  end
end

class Menu2
  attr_reader :item_to_use 
  attr_reader :hidden_move_to_use # Added to store move data

  # --- VERTICAL POSITION ADJUSTMENT ---
  Y_ADJUSTMENT = 90
  
  # --- CUSTOMIZABLE TEXT COLORS ---
  ICON_TEXT_COLOR = Color.new(255, 255, 255)
  TIME_TEXT_COLOR = Color.new(255, 255, 255)
  PERIOD_TEXT_COLOR = Color.new(255, 255, 255)
  DEFAULT_TEXT_COLOR = Color.new(255, 255, 255)	

  # --- CUSTOMIZABLE FONTS ---
  ICON_FONT_NAME    = "poki"	
  TIME_FONT_NAME    = "poki"	
  PERIOD_FONT_NAME  = "poki"	
  DEFAULT_FONT_NAME = "poki"	

  def initialize
    @selected_item = 0
    @items = []
    @item_to_use = nil
    @hidden_move_to_use = nil

    @PokedexCmd = addCmd(["pokedex", "Pokédex", "openPokedex"])
    @bagCmd = addCmd(["bag", "Mochila", "openBag"])
    @partyCmd = addCmd(["pokeball", "Equipo", "openParty"])
    @trainerCmd = addCmd(["trainer", "Tarjeta", "openTrainerCard"])
    @saveCmd = addCmd(["save", "Guardar", "openSave"])
    @optionsCmd = addCmd(["options", "Opciones", "openOptions"])

    @icon_width = 66
    @icon_height = 66
    @text_label_height = 20	
    @n_icons = 6	
    @spacing_x = 40	
    @spacing_y = 20	

    @menu_width = @n_icons * (@icon_width + @spacing_x) - @spacing_x
    @vertical_pitch = @icon_height + @text_label_height + @spacing_y	
    @menu_height = (@items.length / @n_icons.to_f).ceil * @vertical_pitch - @spacing_y

    @x_margin = (Graphics.width - @menu_width) / 2	
    @y_margin = (Graphics.height - @menu_height) / 2 + Y_ADJUSTMENT	

    @exit = false
    @last_time_string = ""
    @last_period_icon = nil
  end

  # ===========================================================================
  # COMMAND METHODS
  # ===========================================================================
  def pbDisplay(message)
  # Change "speech bw" to whichever windowskin you prefer from Graphics/Windowskins/
  msgwindow = pbCreateMessageWindow(@viewport, "Graphics/Windowskins/speech rs")
  msgwindow.width  = 512
    msgwindow.height = 94 # Slightly taller to ensure 2-line clearance
    msgwindow.x      = (Graphics.width - 512) / 2
    msgwindow.y      = Graphics.height - msgwindow.height - 16
	msgwindow.z      = 99999
  pbMessageDisplay(msgwindow, message)
  pbDisposeMessageWindow(msgwindow)
  Input.update
end 

  def openPokedex
    if $player.has_pokedex
      scene = PokemonPokedex_Scene.new
      screen = PokemonPokedexScreen.new(scene)
      pbFadeOutIn { screen.pbStartScreen }
    else
      pbDisplay(_INTL("You don't have a Pokédex yet."))
    end
  end

  def openBag
    scene = PokemonBag_Scene.new
    screen = PokemonBagScreen.new(scene, $bag)
    item = nil
    pbFadeOutIn { item = screen.pbStartScreen }
    
    if item && item != 0
      @item_to_use = item 
      @exit = true 
    end
  end

  def openParty
    if $player.party_count == 0
      pbDisplay(_INTL("You don't have any Pokémon."))
    else
      hidden_move = nil
      pbFadeOutIn do
        sscene = PokemonParty_Scene.new
        sscreen = PokemonPartyScreen.new(sscene, $player.party)
        hidden_move = sscreen.pbPokemonScreen
      end
      
      if hidden_move
        # NEW: Store move data and exit immediately
        @hidden_move_to_use = hidden_move
        @exit = true
      end
    end
  end

  def openTrainerCard
    scene = PokemonTrainerCard_Scene.new
    screen = PokemonTrainerCardScreen.new(scene)
    pbFadeOutIn { screen.pbStartScreen }
  end

  def openSave
    scene = PokemonSave_Scene.new
    screen = PokemonSaveScreen.new(scene)
    if screen.pbSaveScreen
      @exit = true
    end
  end

  def openOptions
    scene = PokemonOption_Scene.new
    screen = PokemonOptionScreen.new(scene)
    pbFadeOutIn { screen.pbStartScreen }
  end

  # ===========================================================================
  # SCENE DRAWING & LOGIC
  # ===========================================================================

  def getTimePeriodData
    current_hour = Time.now.hour
    if current_hour >= 5 && current_hour < 10
      return ["daytime_morning", "Morning"]
    elsif current_hour >= 10 && current_hour < 17
      return ["daytime_afternoon", "Afternoon"]
    elsif current_hour >= 17 && current_hour < 20
      return ["daytime_evening", "Evening"]
    else
      return ["daytime_night", "Night"]
    end
  end
  
  def clearTimeArea
    @sprites["time_overlay"].bitmap.clear
  end

  def drawIconLabels
    text_labels = ["Pokédex", "Bag", "Party", "Trainer", "Save", "Options"]
    text_box_width = 100	
    box_offset = (text_box_width - @icon_width) / 2	

    counter = 0
    @items.each do |item|
      icon_x = @x_margin + ((@icon_width + @spacing_x) * (counter % @n_icons))
      icon_y = @y_margin + (@vertical_pitch * (counter / @n_icons))

      @sprites["item_#{counter}"] = Sprite.new(@viewport)
      @sprites["item_#{counter}"].bitmap = RPG::Cache.ui("Menu Custom/#{item[0]}")
      @sprites["item_#{counter}"].x = icon_x
      @sprites["item_#{counter}"].y = icon_y
      @sprites["item_#{counter}"].z = 101
      
      text_x = icon_x - box_offset
      case counter
      when 0; text_x -= 16
      when 1; text_x -= 34
      when 2; text_x -= 30
      when 3; text_x -= 22
      when 4; text_x -= 29
      when 5; text_x -= 18
      end

      text_y = icon_y + @icon_height + 2
      @sprites["bg"].bitmap.font.name = ICON_FONT_NAME	    
      @sprites["bg"].bitmap.font.size = 23	
      @sprites["bg"].bitmap.font.color = ICON_TEXT_COLOR
      @sprites["bg"].bitmap.draw_text(text_x, text_y, text_box_width, @text_label_height, text_labels[counter], 2)
      counter += 1
    end
  end

  def drawTimeData
    overlay_bitmap = @sprites["time_overlay"].bitmap
    time_string = Time.now.strftime("%l:%M %p").strip	
    
    overlay_bitmap.font.name = TIME_FONT_NAME	     
    overlay_bitmap.font.size = 23
    overlay_bitmap.font.color = TIME_TEXT_COLOR
    overlay_bitmap.draw_text(16, 16, 100, 24, time_string, 0)
    
    icon_name, period_text = getTimePeriodData
    icon_x = Graphics.width - 54
    overlay_bitmap.font.name = PERIOD_FONT_NAME	   
    overlay_bitmap.font.color = PERIOD_TEXT_COLOR
    overlay_bitmap.draw_text(icon_x - 86, 16, 70, 38, period_text, 2)
    @last_time_string = time_string
  end

  def updatePeriodIcon(icon_name)
    @sprites["period_icon"].x = Graphics.width - 54
    @sprites["period_icon"].y = 10
    if icon_name != @last_period_icon
      @sprites["period_icon"].bitmap = RPG::Cache.ui("Menu Custom/#{icon_name}")
      @last_period_icon = icon_name
    end
  end

  def isMouseOverIcon(index)
    sprite = @sprites["item_#{index}"]
    return false if !sprite
    mouse_x = Input.mouse_x
    mouse_y = Input.mouse_y
    return (mouse_x >= sprite.x && mouse_x < sprite.x + sprite.width && 
            mouse_y >= sprite.y && mouse_y < sprite.y + sprite.height)
  end

  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @sprites["map_blur"] = Sprite.new(@viewport)
    @sprites["map_blur"].bitmap = Kernel.pbBlurMap(Graphics.snap_to_bitmap)
    @sprites["map_blur"].z = 99

    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = RPG::Cache.ui("Menu Custom/menubg")
    @sprites["bg"].z = 100 
    
    @sprites["time_overlay"] = Sprite.new(@viewport)
    @sprites["time_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["time_overlay"].z = 102 
    
    @sprites["period_icon"] = Sprite.new(@viewport)
    @sprites["period_icon"].z = 104

    drawIconLabels
    icon_name, _ = getTimePeriodData
    drawTimeData
    updatePeriodIcon(icon_name)

    @sprites["selector"] = Sprite.new(@viewport)
    @sprites["selector"].bitmap = RPG::Cache.ui("Menu Custom/menu_selection")
    redrawSelector
    @sprites["selector"].z = 99999
    pbSEPlay("GUI menu open")
  end

  def pbRefresh
    current_time_string = Time.now.strftime("%l:%M %p").strip
    icon_name, _ = getTimePeriodData
    if current_time_string != @last_time_string || icon_name != @last_period_icon
      clearTimeArea
      drawTimeData
      updatePeriodIcon(icon_name)
    end
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
  end

  def redrawSelector
    icon_base_x = @x_margin + ((@icon_width + @spacing_x) * (@selected_item % @n_icons))
    @sprites["selector"].x = icon_base_x - 17
    @sprites["selector"].y = @y_margin + (@vertical_pitch * (@selected_item / @n_icons))
  end

  def addCmd(item)
    @items.push(item).length - 1
  end

  def pbUpdate
    Input.update 
    loop do
      pbRefresh
      moved = false
      mouse_hover = -1

      @items.each_with_index { |item, i| (mouse_hover = i; break) if isMouseOverIcon(i) }
      
      if mouse_hover >= 0 && @selected_item != mouse_hover
        @selected_item = mouse_hover
        moved = true 
      end

      if Input.trigger?(Input::RIGHT)
        @selected_item += 1; moved = true
      elsif Input.trigger?(Input::LEFT)
        @selected_item -= 1; moved = true
      elsif Input.trigger?(Input::UP)
        @selected_item -= @n_icons; moved = true
        @selected_item = 0 if @selected_item < 0
      elsif Input.trigger?(Input::DOWN)
        @selected_item += @n_icons; moved = true
        @selected_item = @items.length - 1 if @selected_item > @items.length - 1
      end

      @selected_item = @items.length - 1 if @selected_item < 0
      @selected_item = 0 if @selected_item >= @items.length
      pbSEPlay("GUI sel cursor") if moved 

      # Selection Execution
      if Input.press?(1) || Input.trigger?(Input::C)
        pbSEPlay("GUI sel decision")
        send(@items[@selected_item][2])
      end

      if Input.trigger?(Input::B) || @exit
        pbSEPlay("GUI sel cancel")
        break 
      end
    
      redrawSelector
      Graphics.update
      Input.update 
    end
  end
end

def pbCallMenu2
  scene = Menu2.new
  scene.pbStartScene
  scene.pbUpdate
  
  # Capture both potential selections
  item = scene.item_to_use 
  h_move = scene.hidden_move_to_use
  
  # CLOSE THE MENU COMPLETELY
  scene.pbEndScene
  
  # NOW TRIGGER OVERWORLD EFFECTS
  if item && item != 0
    $game_temp.in_menu = false 
    if ItemHandlers.hasOutHandler(item) || ItemHandlers.hasUseInFieldHandler(item)
      ItemHandlers.triggerUseInField(item)
    else
      pbUseItem($bag, item)
    end
  elsif h_move
    # This triggers the Surf/Flash/Cut logic AFTER the menu is gone
    $game_temp.in_menu = false 
    pbUseHiddenMove(h_move[0], h_move[1])
  end
end