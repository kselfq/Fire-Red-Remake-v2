#===============================================================================
# Load Screen - Final Polish with Animated Player Sprite
#===============================================================================
class PokemonLoadPlayerSprite < Sprite
  def initialize(trainer, viewport = nil)
    super(viewport)
    # Checks gender: 0 = Male (introBoy), 1 = Female (introGirl)
    filename = (trainer.gender == 0) ? "Graphics/Pictures/introBoy" : "Graphics/Pictures/introGirl"
    @anim_bitmap = AnimatedBitmap.new(filename)
    self.bitmap = @anim_bitmap.bitmap
    @frame_count = 12
    @width = self.bitmap.width / @frame_count
    @height = self.bitmap.height
    self.src_rect.set(0, 0, @width, @height)
    
    @current_frame = 0
    @timer = 0
    @pause_duration = 80 # 2 seconds at 40fps
    @animating = true
  end

  def update
    return if !@animating
    @timer += 1
    
    if @current_frame < @frame_count
      # Animation playing (roughly 4 frames per image frame)
      if @timer % 6 == 0
        @current_frame += 1
        if @current_frame < @frame_count
          self.src_rect.x = @current_frame * @width
        end
      end
    else
      # Pause duration
      if @timer >= (@frame_count * 6) + @pause_duration
        @current_frame = 0
        @timer = 0
        self.src_rect.x = 0
      end
    end
  end

  def dispose
    @anim_bitmap.dispose
    super
  end
end

class PokemonLoadPanel < Sprite
  attr_reader :selected
  TEXT_COLOR        = Color.new(0, 0, 0)
  TEXT_SHADOW_COLOR = Color.new(0, 0, 0, 0)

  def initialize(index, title, isContinue, trainer, stats, mapid, viewport = nil)
    super(viewport)
    @index = index
    @title = title
    @selected = (index == 0)
    @bgbitmap = AnimatedBitmap.new("Graphics/UI/Load/panels")
    @refreshBitmap = true
    refresh
  end

  def dispose
    @bgbitmap.dispose
    self.bitmap.dispose if self.bitmap
    super
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    @refreshBitmap = true
    refresh
  end

  def pbRefresh; @refreshBitmap = true; refresh; end

  def refresh
    return if disposed?
    if !self.bitmap || self.bitmap.disposed?
      self.bitmap = Bitmap.new(@bgbitmap.width, 46) 
      pbSetSystemFont(self.bitmap)
    end
    if @refreshBitmap
      @refreshBitmap = false
      self.bitmap.clear
      self.bitmap.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 444 + ((@selected) ? 46 : 0), @bgbitmap.width, 46))
      textpos = [[@title, self.bitmap.width / 2, 14, 2, TEXT_COLOR, TEXT_SHADOW_COLOR]]
      pbDrawTextPositions(self.bitmap, textpos)
    end
  end
end

class PokemonLoad_Scene
  def pbStartScene(commands, show_continue, trainer, stats, map_id)
    @commands = commands
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites, "background", "Load/bg", Color.new(248, 248, 248), @viewport)

    if show_continue
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["overlay"].z = 99999
      pbSetSystemFont(@sprites["overlay"].bitmap)
      
      # Time and Map
      totalsec = stats&.play_time.to_i || 0
      time_val = sprintf("%02d:%02d", totalsec / 3600, (totalsec / 60) % 60)
      mapname = _INTL("Unknown Area")
      if map_id > 0
        begin
          mapname = GameData::MapMetadata.get(map_id).name
        rescue
          mapname = pbGetMapNameFromID(map_id) rescue _INTL("Area {1}", map_id)
        end
      end
      
      base, shadow = Color.new(255, 255, 255), Color.new(0, 0, 0, 0)
      mid_x = 300
      lx, vx = mid_x - 120, mid_x - 10
      
      textpos = [
        [trainer.name, lx, Graphics.height * 0.22, 0, base, shadow],
        [mapname, lx, Graphics.height * 0.30, 0, base, shadow],
        [_INTL("Pokédex:"), lx, Graphics.height * 0.38, 0, base, shadow],
        [_INTL("{1} Pokémon", trainer.pokedex.seen_count), vx, Graphics.height * 0.38, 0, base, shadow],
        [_INTL("Play time:"), lx, Graphics.height * 0.46, 0, base, shadow],
        [time_val, vx, Graphics.height * 0.46, 0, base, shadow]
      ]
      pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)

      # Animated Player Sprite
      @sprites["player"] = PokemonLoadPlayerSprite.new(trainer, @viewport)
      @sprites["player"].x = lx - @sprites["player"].src_rect.width + 520
      @sprites["player"].y = 0
    end

    # Buttons
    start_y = Graphics.height - 150 - 16
    commands.length.times do |i|
      @sprites["panel#{i}"] = PokemonLoadPanel.new(i, commands[i], false, trainer, stats, map_id, @viewport)
      @sprites["panel#{i}"].x = (Graphics.width - @sprites["panel#{i}"].bitmap.width) / 2
      @sprites["panel#{i}"].y = start_y + (i * 52)
    end
    
    # Cursor
    @sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].bitmap = Bitmap.new("Graphics/UI/sel_arrow")
    @sprites["cursor"].z = 100000
    @cursor_frame = 0 
    update_cursor_position(0)
    
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
  end

  def update_cursor_position(index)
    return if !@sprites["panel#{index}"]
    @cursor_base_x = @sprites["panel#{index}"].x - @sprites["cursor"].bitmap.width + 10
    @sprites["cursor"].y = @sprites["panel#{index}"].y + (46 - @sprites["cursor"].bitmap.height) / 2
  end

  def pbSetParty(trainer); end
  def pbStartScene2; pbFadeInAndShow(@sprites) { pbUpdate }; end

  def pbUpdate
    oldi = @sprites["cmdwindow"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    newi = @sprites["cmdwindow"].index rescue 0
    if oldi != newi
      @sprites["panel#{oldi}"].selected = false if @sprites["panel#{oldi}"]
      @sprites["panel#{newi}"].selected = true if @sprites["panel#{newi}"]
      update_cursor_position(newi)
    end
    # Cursor Bobbing
    if @sprites["cursor"]
      @cursor_frame += 1
      @sprites["cursor"].x = @cursor_base_x + (Math.sin(@cursor_frame * 0.15) * 4).round
    end
    # Player Animation Update
    @sprites["player"].update if @sprites["player"]
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    loop do
      Graphics.update; Input.update; pbUpdate
      return @sprites["cmdwindow"].index if Input.trigger?(Input::USE)
      return -1 if Input.trigger?(Input::BACK)
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    @save_data = SaveData.exists? ? SaveData.read_from_file(SaveData::FILE_PATH) : {}
  end

  def pbStartLoadScreen
    commands = []
    cmd_continue = cmd_new_game = cmd_options = -1
    show_continue = !@save_data.empty?
    commands[cmd_continue = commands.length] = _INTL("Continue your adventure") if show_continue
    commands[cmd_new_game = commands.length] = _INTL("Start a new game")
    commands[cmd_options = commands.length]  = _INTL("Change your options")
    
    map_id = show_continue ? (@save_data[:map_factory].map.map_id rescue 0) : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
    @scene.pbStartScene2
    
    loop do
      command = @scene.pbChoose(commands)
      case command
      when cmd_continue
        @scene.pbEndScene; Game.load(@save_data); return
      when cmd_new_game
        @scene.pbEndScene; Game.start_new; return
      when cmd_options
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        }
      when -1 then break
      end
    end
    @scene.pbEndScene
  end
end