def pbEmergencySave
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$player
  if SaveData.exists?
    File.open(SaveData::FILE_PATH, "rb") do |r|
      File.open(SaveData::FILE_PATH + ".bak", "wb") do |w|
        loop do
          s = r.read(4096)
          break if !s
          w.write(s)
        end
      end
    end
  end
  if Game.save
    pbDisplay("\\se[]" + _INTL("The game was saved.") + "\\me[GUI save game]\\wtnp[20]")
    pbDisplay("\\se[]" + _INTL("The previous save file has been backed up.") + "\\wtnp[20]")
  else
    pbDisplay("\\se[]" + _INTL("Save failed.") + "\\wtnp[30]")
  end
  $scene = oldscene
end

#===============================================================================
#
#===============================================================================
class PokemonSave_Scene
  LOCATION_TEXT_BASE   = Color.new(161, 83, 34)   # Green
  LOCATION_TEXT_SHADOW = Color.new(192, 32, 40, 0)
  MALE_TEXT_BASE       = Color.new(56, 24, 1)   # Blue
  MALE_TEXT_SHADOW     = Color.new(192, 32, 40, 0)
  FEMALE_TEXT_BASE     = Color.new(56, 24, 1)   # Red
  FEMALE_TEXT_SHADOW   = Color.new(192, 32, 40, 0)
  OTHER_TEXT_BASE      = Color.new(161, 83, 34)   # Blue
  OTHER_TEXT_SHADOW    = Color.new(192, 32, 40, 0)

  def pbStartScreen
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    mapname = $game_map.name
    if $player.male?
      text_tag = shadowc3tag(MALE_TEXT_BASE, MALE_TEXT_SHADOW)
    elsif $player.female?
      text_tag = shadowc3tag(FEMALE_TEXT_BASE, FEMALE_TEXT_SHADOW)
    else
      text_tag = shadowc3tag(OTHER_TEXT_BASE, OTHER_TEXT_SHADOW)
    end
    location_tag = shadowc3tag(LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW)
    loctext = location_tag + "<ac>" + mapname + "</ac></c3>"
    loctext += _INTL("Player") + "<r>" + text_tag + $player.name + "</c3><br>"
    if hour > 0
      loctext += _INTL("Time") + "<r>" + text_tag + _INTL("{1}h {2}m", hour, min) + "</c3><br>"
    else
      loctext += _INTL("Time") + "<r>" + text_tag + _INTL("{1}m", min) + "</c3><br>"
    end
    loctext += _INTL("Badges") + "<r>" + text_tag + $player.badge_count.to_s + "</c3><br>"
    if $player.has_pokedex
      loctext += _INTL("Pokédex") + "<r>" + text_tag + $player.pokedex.owned_count.to_s + "/" + $player.pokedex.seen_count.to_s + "</c3>"
    end
    @sprites["locwindow"] = Window_AdvancedTextPokemon.new(loctext)
    @sprites["locwindow"].viewport = @viewport
	
	
    
    # --- CHANGE WINDOWSKIN HERE ---
    # Replace "speech rs" with your preferred filename from Graphics/Windowskins/
    @sprites["locwindow"].setSkin("Graphics/Windowskins/speech pl 20") 
    # ------------------------------
	@sprites["locwindow"].width = 228 if @sprites["locwindow"].width < 228
    @sprites["locwindow"].x = (Graphics.width - @sprites["locwindow"].width) / 2
    @sprites["locwindow"].y = 16
    @sprites["locwindow"].width = 228 if @sprites["locwindow"].width < 228
    @sprites["locwindow"].visible = true
  end
  end

#===============================================================================
#
#===============================================================================
class PokemonSaveScreen
  def initialize(scene)
    @scene = scene
  end

  def pbDisplay(message)
  # Change "speech bw" to whichever windowskin you prefer from Graphics/Windowskins/
  msgwindow = pbCreateMessageWindow(@viewport, "Graphics/Windowskins/speech rs")
  pbMessageDisplay(msgwindow, message)
  pbDisposeMessageWindow(msgwindow)
  Input.update
end

  def pbDisplayPaused(text)
    @scene.pbDisplayPaused(text)
  end

  #def pbConfirm(text)
  #  return @scene.pbConfirm(text)
  #end


	def pbConfirmMessage(message)
    # Attempt to get the viewport from the scene
    view = (@scene && @scene.instance_variable_defined?(:@viewport)) ? @scene.instance_variable_get(:@viewport) : nil
    # Create the window with your custom skin
    msgwindow = pbCreateMessageWindow(view, "Graphics/Windowskins/speech rs")
    msgwindow.text = message
    # Show the Yes/No choices
    ret = pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 1)
    pbDisposeMessageWindow(msgwindow)
    return ret == 0
  end
  
  def pbConfirmMessageSerious(message)
    return pbConfirmMessage(message)
  end
  
  def pbSaveScreen
    ret = false
    @scene.pbStartScreen
    view = (@scene && @scene.instance_variable_defined?(:@viewport)) ? @scene.instance_variable_get(:@viewport) : nil
	
	# --- 0. HIGH-INTENSITY STATIC BLUR ---
    blur_sprite = Sprite.new(view)
    blur_sprite.bitmap = Graphics.snap_to_bitmap
    blur_sprite.z = -10 
    
    # We work at 1/3 resolution to make the blur radius feel 3x larger
    bm = blur_sprite.bitmap
    small_bm = Bitmap.new(bm.width / 3, bm.height / 3)
    small_bm.stretch_blt(small_bm.rect, bm, bm.rect)
    
    # 4-Pass Cross-Blur (Up, Down, Left, Right)
    # This removes the "motion" look and makes it a static "frosted glass" effect
    4.times do
      temp_bm = small_bm.clone
      opacity = 128 # 50% blend for smooth averaging
      small_bm.blt(2, 0, temp_bm, temp_bm.rect, opacity)  # Right
      small_bm.blt(-2, 0, temp_bm, temp_bm.rect, opacity) # Left
      small_bm.blt(0, 2, temp_bm, temp_bm.rect, opacity)  # Down
      small_bm.blt(0, -2, temp_bm, temp_bm.rect, opacity) # Up
      temp_bm.dispose
    end
    
    bm.clear
    bm.stretch_blt(bm.rect, small_bm, small_bm.rect)
    small_bm.dispose
    
    # Darken the background slightly more for better contrast
    blur_sprite.color = Color.new(0, 0, 0, 80)
	
    # --- 0. BACKGROUND IMAGE ---
    background = Sprite.new(view)
    background.bitmap = Bitmap.new("Graphics/UI/save_bg")
    background.z = 0 # Lowest layer
    # Optional: Center it if the image is smaller than the screen
    background.x = 0
    background.y = 0
	
	# --- 2. PLAYER CHARACTER ANIMATED GRAPHIC ---
    player_sprite = Sprite.new(view)
    if $player.male?
      player_sprite.bitmap = Bitmap.new("Graphics/Pictures/introBoy")
    else
      player_sprite.bitmap = Bitmap.new("Graphics/Pictures/introGirl")
    end
    player_sprite.z = 5 
    
    # --- ANIMATION CALCULATIONS ---
    # Total Width: 1208 | Total Height: 626 | Frames: 4
    frames_count = 12      
    frame_width  = 302    # 1208 divided by 4
    frame_height = 384  

	# Timing variables
    anim_speed  = 6                      # Frames per sprite change
    pause_time  = 120                    # 120 frames = 2 seconds at 60fps
    # Total frames it takes to run the 4-frame animation once
    play_duration = frames_count * anim_speed 
    # Total loop duration (Animation + Pause)
    total_cycle   = play_duration + pause_time	
    
    # Set the initial "viewing window" to the first frame
    player_sprite.src_rect.set(0, 0, frame_width, frame_height)
    
    
    # --- MANUAL X/Y POSITIONING ---
    player_sprite.x = 32  # Change this value to move Left/Right
    player_sprite.y = 0 # Change this value to move Up/Down
	
    # --- 1. CREATE THE EMPTY BARS ---
    save_btn = Window_AdvancedTextPokemon.new("")
    save_btn.viewport = view
    save_btn.width = 512
    save_btn.height = 38
    
    back_btn = Window_AdvancedTextPokemon.new("")
    back_btn.viewport = view
    back_btn.width = 512
    back_btn.height = 38
    
    # --- POSITIONING ---
    back_btn.x = (Graphics.width - back_btn.width) / 2
    back_btn.y = Graphics.height - back_btn.height - 16
    
    save_btn.x = back_btn.x
    save_btn.y = back_btn.y - save_btn.height - 8 # 8px gap

    # --- 2. CREATE THE TEXT OVERLAYS ---
    text_overlay = BitmapSprite.new(Graphics.width, Graphics.height, view)
    text_overlay.z = save_btn.z + 10
    pbSetSystemFont(text_overlay.bitmap)
    
    def draw_button_text(overlay, s_btn, b_btn)
      overlay.bitmap.clear
      # CHANGED: Base color is now pure black (0,0,0)
      base = Color.new(0, 0, 0)
      textpos = [
         [_INTL("Save your progress"), s_btn.x + 256, s_btn.y + 8, 2, base, nil],
         [_INTL("Back to your adventure"), b_btn.x + 256, b_btn.y + 8, 2, base, nil]
      ]
      pbDrawTextPositions(overlay.bitmap, textpos)
    end
    
    draw_button_text(text_overlay, save_btn, back_btn)

    # --- 3. CURSOR SETUP ---
    cursor = Sprite.new(view)
    cursor.bitmap = Bitmap.new("Graphics/UI/sel_arrow")
    cursor.z = 999999 
    
    begin
      index = 0 
      frame = 0
      loop do
	  # --- ANIMATE THE SPRITE ---
        # The number 8 determines speed; higher = slower.
        # (frame / 8) % 4 will cycle: 0, 1, 2, 3, 0, 1...
		current_tick = frame % total_cycle
        if current_tick < play_duration
          # We are in the "Playing" phase
          anim_index = current_tick / anim_speed
        else
          # We are in the "Pause" phase (Stay on the last frame or first)
          # Change to 0 if you want it to reset to the first frame during the pause
          anim_index = 0 
        end
        
        player_sprite.src_rect.x = anim_index * frame_width
		
        # Dynamic Skins
        save_btn.setSkin(index == 0 ? "Graphics/Windowskins/button sel" : "Graphics/Windowskins/button unsel")
        back_btn.setSkin(index == 1 ? "Graphics/Windowskins/button sel" : "Graphics/Windowskins/button unsel")
        
        target_btn = (index == 0) ? save_btn : back_btn
        cursor.x = target_btn.x - 11 + (frame / 24 % 2 == 0 ? -4 : 4)
        cursor.y = target_btn.y + (target_btn.height - cursor.bitmap.height) / 2
        
        Graphics.update
        Input.update
        frame += 1
        
        if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
          index = (index == 0) ? 1 : 0
          pbPlayCursorSE
          draw_button_text(text_overlay, save_btn, back_btn)
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          break
        elsif Input.trigger?(Input::BACK)
          index = 1
          pbPlayCancelSE
          break
        end
      end
      
      # Immediate cleanup of info window
      if @scene && @scene.instance_variable_defined?(:@sprites)
        sprites_hash = @scene.instance_variable_get(:@sprites)
        if sprites_hash["locwindow"]
          sprites_hash["locwindow"].dispose
          sprites_hash.delete("locwindow")
        end
      end
      
	  player_sprite.dispose
      text_overlay.dispose
      cursor.dispose
      save_btn.dispose
      back_btn.dispose
      
      if index == 0
        if SaveData.exists? && $game_temp.begun_new_game
          pbDisplay(_INTL("WARNING!") + "\1")
          pbDisplay(_INTL("There is a different game file that is already saved.") + "\1")
          pbDisplay(_INTL("If you save now, the other file's adventure, including items and Pokémon, will be entirely lost.") + "\1")
          if !pbConfirmMessageSerious(_INTL("Would you want to overwrite the other save file?"))
            pbSEPlay("GUI save choice")
            return false
          end
        end
        $game_temp.begun_new_game = false
        pbSEPlay("GUI save choice")
        if Game.save
          pbDisplay("\\se[]" + _INTL("{1} saved the game.", $player.name) + "\\me[GUI save game]\\wtnp[20]")
          ret = true
        else
          pbDisplay("\\se[]" + _INTL("Save failed.") + "\\wtnp[30]")
          ret = false
        end
      else
        pbSEPlay("GUI save choice")
      end
      
    ensure
      # Safety disposal
      [blur_sprite, background, player_sprite, text_overlay, cursor, save_btn, back_btn].each { |s| s.dispose if s && !s.disposed? }
      @scene.pbEndScreen if @scene && @scene.respond_to?(:pbEndScreen)
    end
    
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end
