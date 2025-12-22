#===============================================================================
# Ensure pbBlurMap is defined and control its blur strength
#===============================================================================
unless Kernel.respond_to?(:pbBlurMap)
  def pbBlurMap(bitmap)
    if bitmap.is_a?(Bitmap)
      bitmap.blur 
      bitmap.blur 
      bitmap.blur 
      bitmap.blur 
      bitmap.blur 
      bitmap.blur 
      bitmap.blur 
      bitmap.blur 	
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
  # --- VERTICAL POSITION ADJUSTMENT ---
  # Increase this value to move all icons and labels further down the screen.
  Y_ADJUSTMENT = 90 
  # ------------------------------------
  SELECTOR_X_OFFSET = - 11
  
  # --- CUSTOMIZABLE TEXT COLORS ---
  
  # 1. Main Icon Text Labels (Pokedex, Bag, Player Name, etc.)
  ICON_TEXT_COLOR = Color.new(255, 255, 255)

  # 2. Top-Left Current Time
  TIME_TEXT_COLOR = Color.new(255, 255, 255)

  # 3. Top-Right Time Period Label (Morning, Night, etc.)
  PERIOD_TEXT_COLOR = Color.new(255, 255, 255)
  
  # Default color constants (used for cleanup)
  DEFAULT_TEXT_COLOR = Color.new(255, 255, 255)	

  # --- CUSTOMIZABLE FONTS ---
  ICON_FONT_NAME    = "poki"	
  TIME_FONT_NAME    = "poki"	
  PERIOD_FONT_NAME  = "poki"	
  
  # FIX: Replaced MessageConfig::FontName with a reliable string default.
  DEFAULT_FONT_NAME = "poki"	
  # --------------------------------

  def initialize
    @selected_item = 0
    @items = []

    @PokedexCmd = addCmd(["pokedex", "Pokédex", "openPokedex"])
    @bagCmd = addCmd(["bag", "Mochila", "openBag"])
    @partyCmd = addCmd(["pokeball", "Equipo", "openParty"])
    @trainerCmd = addCmd(["trainer", "Tarjeta", "openTrainerCard"])
    @saveCmd = addCmd(["save", "Guardar", "openSave"])
    @optionsCmd = addCmd(["options", "Opciones", "openOptions"])

    #@debugCmd = addCmd(["debug", "Debug", "pbDebugMenu"]) if $DEBUG
    #@exitCmd = addCmd(["exit", "Salir", "exitMenu"])

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
    # Apply the vertical adjustment here
    @y_margin = (Graphics.height - @menu_height) / 2 + Y_ADJUSTMENT	

    @exit = false
    
    # Store previous time data to check for updates
    @last_time_string = ""
    @last_period_icon = nil
  end
  
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
  
  # Clears only the dedicated time overlay bitmap (Text only)
  def clearTimeArea
    @sprites["time_overlay"].bitmap.clear
  end

  # Draws the static icon labels (only runs once)
  def drawIconLabels
    # Text labels array
    text_labels = [
      "Pokédex", "Bag", "Party", "Trainer", "Save", "Options" #$player.name
    ]
    
    # --- Icon Centering Variables ---
    text_box_width = 100	
    box_offset = (text_box_width - @icon_width) / 2	

    counter = 0
    @items.each do |item|
      icon_x = @x_margin + ((@icon_width + @spacing_x) * (counter % @n_icons))
      # icon_y calculation relies on @y_margin, which includes the Y_ADJUSTMENT
      icon_y = @y_margin + (@vertical_pitch * (counter / @n_icons))

      # 1. Draw Icon Sprite 
      @sprites["item_#{counter}"] = Sprite.new(@viewport)
      @sprites["item_#{counter}"].bitmap = RPG::Cache.ui("Menu Custom/#{item[0]}")
      @sprites["item_#{counter}"].x = icon_x
      @sprites["item_#{counter}"].y = icon_y
      @sprites["item_#{counter}"].z = 101
      
      # 2. Determine Text Drawing Box X-Position (Manual Centering Logic)
      text_x = icon_x - box_offset
      
      # --- Manual Adjustment for Visual Centering ---
      case counter
      when 0 # Pokedex
        text_x -= 16
      when 1 # Bag
        text_x -= 34
      when 2 # Party
        text_x -= 30
      when 3 # Trainer
        text_x -= 22
      when 4 # Save
        text_x -= 29
      when 5 # Options
        text_x -= 18
      end
      # ------------------------------------------------------------------

      # 3. Draw Text Label	(Drawn on the main BG bitmap)
      text_y = icon_y + @icon_height + 2
      
      # --- Set Font for Main Icon Labels ---
      @sprites["bg"].bitmap.font.name = ICON_FONT_NAME	    
      @sprites["bg"].bitmap.font.size = 23	
      @sprites["bg"].bitmap.font.bold = false
      @sprites["bg"].bitmap.font.color = ICON_TEXT_COLOR
      
      @sprites["bg"].bitmap.draw_text(
        text_x, text_y, text_box_width, @text_label_height,
        text_labels[counter], 2
      )
      
      counter += 1
    end
  end

  # Draws/Redraws the time and period TEXT onto the dedicated overlay.
  def drawTimeData
    overlay_bitmap = @sprites["time_overlay"].bitmap
    
    # =======================================================
    # Draw Current Time (Top Left) - No change to Y position here
    # =======================================================
    time_string = Time.now.strftime("%l:%M %p").strip	
    time_margin_x = 16	 
    time_margin_y = 16	 
    time_width = 100	 
    time_height = 24	 

    # --- Set Font for Time Label ---
    overlay_bitmap.font.name = TIME_FONT_NAME	     
    overlay_bitmap.font.size = 23
    overlay_bitmap.font.bold = false
    overlay_bitmap.font.color = TIME_TEXT_COLOR
    
    overlay_bitmap.draw_text(
      time_margin_x, time_margin_y, time_width, time_height,
      time_string, 0
    )
    
    # =======================================================
    # Draw Time Period Text (Top Right - Left of the Icon) - No change to Y position here
    # =======================================================
    
    icon_name, period_text = getTimePeriodData
    
    period_icon_size = 38
    period_spacing = 16
    text_width_estimate = 70	
    
    # Calculate Icon position (Rightmost)
    icon_x = Graphics.width - 16 - period_icon_size
    icon_y = 16	

    # Calculate Text position (Left of Icon)
    text_x = icon_x - period_spacing - text_width_estimate
	
    
    # --- Set Font for Time Period Label ---
    overlay_bitmap.font.name = PERIOD_FONT_NAME	   
    overlay_bitmap.font.size = 23	
    overlay_bitmap.font.bold = false	
    overlay_bitmap.font.color = PERIOD_TEXT_COLOR
    
    overlay_bitmap.draw_text(
      text_x, icon_y, text_width_estimate, period_icon_size,
      period_text, 2 # Left justify text within the defined box
    )
    
    # =======================================================
    # Reset font color/size/NAME
    overlay_bitmap.font.color = DEFAULT_TEXT_COLOR
    overlay_bitmap.font.size = 23	
    overlay_bitmap.font.bold = false
    overlay_bitmap.font.name = DEFAULT_FONT_NAME
    # =======================================================
    
    @last_time_string = time_string # Store the current time
  end

  # Handles the separate drawing and position of the period icon sprite
  def updatePeriodIcon(icon_name)
    period_icon_size = 38
    period_spacing = 16
    text_width_estimate = 70	
    
    # Icon is the rightmost element
    icon_x = Graphics.width - 16 - period_icon_size
    icon_y = 10
    
    # Position the independent sprite
    @sprites["period_icon"].x = icon_x
    @sprites["period_icon"].y = icon_y
    
    # Update the bitmap if the time period changed
    if icon_name != @last_period_icon
      @sprites["period_icon"].bitmap = RPG::Cache.ui("Menu Custom/#{icon_name}")
      @last_period_icon = icon_name
    end
  end


  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    # =======================================================
    # Draw Blurred Map Background
    # =======================================================
    @sprites["map_blur"] = Sprite.new(@viewport)
    @sprites["map_blur"].bitmap = pbBlurMap(Graphics.snap_to_bitmap)
    @sprites["map_blur"].z = 99
    # =======================================================

    # --- Menu Background (Semi-transparent image drawn over blur) ---
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = RPG::Cache.ui("Menu Custom/menubg")
    @sprites["bg"].z = 100 
    
    # NEW: Dedicated overlay for dynamic TEXT (time/period)
    @sprites["time_overlay"] = Sprite.new(@viewport)
    @sprites["time_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["time_overlay"].z = 102 # Above the BG
    
    # NEW: Dedicated sprite for the PERIOD ICON (never cleared)
    @sprites["period_icon"] = Sprite.new(@viewport)
    @sprites["period_icon"].z = 104 # Highest Z-level for time elements

    # Draw static text (Icon Labels) on the main BG bitmap
    drawIconLabels
    
    # Draw initial time data: Text first (on overlay), Icon second (independent sprite)
    icon_name, _ = getTimePeriodData
    
    drawTimeData
    updatePeriodIcon(icon_name)

    # --- Selector ---
    @sprites["selector"] = Sprite.new(@viewport)
    @sprites["selector"].bitmap = RPG::Cache.ui("Menu Custom/menu_selection")
    # redrawSelector handles the Y_ADJUSTMENT inherited by @y_margin
    redrawSelector
    @sprites["selector"].z = 99999

    pbSEPlay("GUI menu open")
  end
  

  def pbRefresh
    # Get the current time and period for comparison
    current_time_string = Time.now.strftime("%l:%M %p").strip
    icon_name, _ = getTimePeriodData
    
    # Check if *any* update is needed
    if current_time_string != @last_time_string || icon_name != @last_period_icon
      
      # 1. Clear the text overlay bitmap
      clearTimeArea
      
      # 2. Redraw time/period text onto the overlay (Text is on the left)
      drawTimeData
      
      # 3. Update the static icon (position and potentially bitmap). (Icon is on the right)
      updatePeriodIcon(icon_name)
    end
  end

  def pbEndScene
    pbDisposeSprite(@sprites, "map_blur")
    pbDisposeSprite(@sprites, "time_overlay")
    pbDisposeSprite(@sprites, "period_icon") # Dispose new icon sprite
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
  end

def redrawSelector
    # 1. Calculate the base X position of the icon
    icon_base_x = @x_margin + ((@icon_width + @spacing_x) * (@selected_item % @n_icons))
    
    # 2. Apply a direct subtraction of 11 pixels to the X position
    @sprites["selector"].x = icon_base_x - 17 
    
    # 3. Y position remains the same
    @sprites["selector"].y = @y_margin + (@vertical_pitch * (@selected_item / @n_icons))
  end

  def addCmd(item)
    @items.push(item).length - 1
  end

  def pbUpdate
    loop do
      Input.update
      
      # The core update loop now runs the refresh check
      pbRefresh

      moved = false # Flag to track if navigation occurred

      if Input.trigger?(Input::RIGHT)
        @selected_item += 1
        moved = true
		
      elsif Input.trigger?(Input::LEFT)
        @selected_item -= 1
        moved = true
		
      elsif Input.trigger?(Input::UP)
        @selected_item -= @n_icons
		
        @selected_item = 0 if @selected_item < 0
        moved = true
      elsif Input.trigger?(Input::DOWN)
	
        @selected_item += @n_icons
        @selected_item = @items.length - 1 if @selected_item > @items.length - 1
        moved = true
      end

      @selected_item = @items.length - 1 if @selected_item < 0
      @selected_item = 0 if @selected_item >= @items.length
      
      # Play sound if the selection moved
      pbSEPlay("GUI sel cursor") if moved 

      if Input.trigger?(Input::C)
        pbSEPlay("GUI sel decision") # Add a selection sound
        send(@items[@selected_item][2])
      end

      if Input.trigger?(Input::B) || @exit
        pbSEPlay("GUI sel cancel") # Play sound when exiting
        break 
      end
	

      redrawSelector
      Graphics.update
    end
  end
end

def pbCallMenu2
  scene = Menu2.new
  scene.pbStartScene
  scene.pbUpdate
  scene.pbEndScene
end

def exitMenu
  @exit = true
end

def openOptions
  scene = PokemonOption_Scene.new
  screen = PokemonOptionScreen.new(scene)
  pbFadeOutIn { screen.pbStartScreen }
end

def openBag
  scene = PokemonBag_Scene.new
  screen = PokemonBagScreen.new(scene, $bag)
  pbFadeOutIn { screen.pbStartScreen }
end

def openParty
  if $player.party_count == 0
    pbMessage(_INTL("You don't have any Pokémon."))
  else
    hidden_move = nil
    pbFadeOutIn do
      sscene = PokemonParty_Scene.new
      sscreen = PokemonPartyScreen.new(sscene, $player.party)
      hidden_move = sscreen.pbPokemonScreen
    end

    if hidden_move
      $game_temp.in_menu = false
      pbUseHiddenMove(hidden_move[0], hidden_move[1])
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

def openPokedex
  if $player.has_pokedex
    scene = PokemonPokedex_Scene.new
    screen = PokemonPokedexScreen.new(scene)
    pbFadeOutIn { screen.pbStartScreen }
  else
    pbMessage(_INTL("You don't have a Pokédex yet."))
  end
end