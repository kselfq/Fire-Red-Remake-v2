#===============================================================================
#  Target selection UI
#===============================================================================
class TargetWindowEBDX
  attr_reader :index
  #-----------------------------------------------------------------------------
  #  PBS metadata
  #-----------------------------------------------------------------------------
  def applyMetrics
    # sets default values
    @btnImg = "btnEmpty"
    @selImg = "cmdSel"
    @btnImgFoe  = "redbutton"
    @btnImgAlly = "bluebutton"

    # looks up next cached metrics first
    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:TARGETMENU] if !d1.nil? && d1.has_key?(:TARGETMENU)
    # looks up globally defined settings
    d2 = EliteBattle.get_data(:TARGETMENU, :Metrics, :METRICS)
    # looks up globally defined settings
    d7 = EliteBattle.get_map_data(:TARGETMENU_METRICS)
    # look up trainer specific metrics
    d6 = @battle.opponent ? EliteBattle.get_trainer_data(@battle.opponent[0].trainer_type, :TARGETMENU_METRICS, @battle.opponent[0]) : nil
    # looks up species specific metrics
    d5 = !@battle.opponent ? EliteBattle.get_data(@battle.battlers[1].species, :Species, :TARGETMENU_METRICS, (@battle.battlers[1].form rescue 0)) : nil
    # proceeds with parameter definition if available
    for data in [d2, d7, d6, d5, d1]
      if !data.nil?
        # applies a set of predefined keys
        @btnImg = data[:BUTTONGRAPHIC] if data.has_key?(:BUTTONGRAPHIC) && data[:BUTTONGRAPHIC].is_a?(String)
        @selImg = data[:SELECTORGRAPHIC] if data.has_key?(:SELECTORGRAPHIC) && data[:SELECTORGRAPHIC].is_a?(String)
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  initialize all the required components
  #-----------------------------------------------------------------------------
  def initialize(viewport, battle, scene)
    @viewport = viewport
    @battle = battle
    @scene = scene
    @index = 0
    @disposed = false
    # button sprite hash
    @buttons = {}
    # apply all the graphic path data
    @path = "Graphics/EBDX/Pictures/UI/"
    self.applyMetrics
    # set up selector sprite
    @sel = SelectorSprite.new(@viewport, 4)
    @sel.filename = @path + @selImg
    @sel.z = 99999
    # set up background graphic
    @background = Sprite.new(@viewport)
    @background.create_rect(@viewport.width, 64, Color.new(0, 0, 0, 0))
    @background.bitmap = pbBitmap(@path + @barImg) if !@barImg.nil?
    @background.y = Graphics.height - @background.bitmap.height + 80
    @background.z = 100
  end
  #-----------------------------------------------------------------------------
  #  re-draw buttons for current context and selectable battlers
  #-----------------------------------------------------------------------------
def refresh(texts)
  pbDisposeSpriteHash(@buttons)

  # Load both button bitmaps once
  bmp_foe  = pbBitmap(@path + @btnImgFoe)
  bmp_ally = pbBitmap(@path + @btnImgAlly)

  # Determine width/height from ally button (they must match sizes)
  bw = bmp_ally.width
  bh = bmp_ally.height

  # Compute grid layout
  #rw = @battle.pbMaxSize * (bw + 8)
  #rh = 2 * (bh + 4)
spacing = 4
rw = @battle.pbMaxSize * (bw + spacing)
rh = 2 * (bh + spacing)


  battlers = @battle.battlers

  for i in 0...battlers.length
    b = battlers[i]

    # Choose button graphic based on side
    # FoE battlers are always at index 1..3 (opposing side)
    bmp = (b.opposes?) ? bmp_foe : bmp_ally

    @buttons["#{i}"] = Sprite.new(@viewport)
    @buttons["#{i}"].bitmap = Bitmap.new(bw, bh)
    @buttons["#{i}"].bitmap.blt(0, 0, bmp, bmp.rect)

    # Always draw Pokémon icon
    if b.displayPokemon
      pkmn = b.displayPokemon
      icon = pbBitmap(GameData::Species.icon_filename_from_pokemon(pkmn))
      ix = (bw - icon.width / 2) / 2
      iy = (bh - icon.height) / 2 - 9
      @buttons["#{i}"].bitmap.blt(ix, iy, icon, Rect.new(0, 0, icon.width/2, bh - 4 - iy), 216)
    end

    # Grey out fainted
# Strong grey-out for fainted Pokémon
if b.hp <= 0
  @buttons["#{i}"].opacity = 180    # darker, fainted effect
  @buttons["#{i}"].color = Color.new(100, 100, 100, 160)  # strong grey overlay
  @buttons["#{i}"].tone = Tone.new(-255, -255, -255) 
elsif texts[i].nil?
  # mild grey-out for empty/unselectable
  @buttons["#{i}"].opacity = 180
  @buttons["#{i}"].color = Color.new(100, 100, 100, 80)
else
  # fully normal
  @buttons["#{i}"].opacity = 255
  @buttons["#{i}"].color = Color.new(0, 0, 0, 0)
end


    # Position (same as you currently have)
x = (@viewport.width - rw) / 2 + (i / 2) * (bw + spacing)
y = (@viewport.height - rh - 4) + (1 - i % 2) * (bh + spacing)



    x_offset = 270
    y_offset = 114

    @buttons["#{i}"].x = x + x_offset
    @buttons["#{i}"].y = y + y_offset
    @buttons["#{i}"].z = 100
  end

  # Dispose bitmaps
  bmp_foe.dispose
  bmp_ally.dispose
end




  #-----------------------------------------------------------------------------
  #  set new index
  #-----------------------------------------------------------------------------
  def index=(val)
  @index = val
  btn = @buttons["#{@index}"]
  return if btn.nil?   # btn might be nil if we skipped creating it (e.g. fainted)
  @sel.target(btn)
  btn.src_rect.y = -4
end

  #-----------------------------------------------------------------------------
  #  update target window
  #-----------------------------------------------------------------------------
  def update
    for key in @buttons.keys
      @buttons[key].src_rect.y += 1 if @buttons[key].src_rect.y < 0
    end
    @sel.update
  end
  #-----------------------------------------------------------------------------
  #  play animation for showing window
  #-----------------------------------------------------------------------------
  def showPlay
    10.times do
      for key in @buttons.keys
        @buttons[key].y -= 12
      end
      @background.y -= 8
      @scene.wait
    end
  end
  #-----------------------------------------------------------------------------
  #  play animation for hiding window
  #-----------------------------------------------------------------------------
  def hidePlay
    @sel.visible = false
    10.times do
      for key in @buttons.keys
        @buttons[key].y += 12
      end
      @background.y += 8
      @scene.wait
    end
  end
  #-----------------------------------------------------------------------------
  #  dispose all sprites
  #-----------------------------------------------------------------------------
  def dispose
    return if self.disposed?
    @sel.dispose
    @background.dispose
    pbDisposeSpriteHash(@buttons)
    @disposed = true
  end
  def disposed?; return @disposed; end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Target Choice functionality part
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  #  Main selection override
  #-----------------------------------------------------------------------------
alias pbChooseTarget_ebdx pbChooseTarget unless self.method_defined?(:pbChooseTarget_ebdx)
def pbChooseTarget(idxBattler, target_data, visibleSprites = nil)
  # hide fight menu
  @fightWindow.hidePlay
  # create array of battler names
  texts = pbCreateTargetTexts(idxBattler,target_data)
  # mode 0 = single target, 1 = multiple
  mode = (target_data.num_targets == 1) ? 0 : 1
  # refresh target window
  @targetWindow.refresh(texts)

  # --- INITIAL INDEX: first alive opposing, fallback first alive any ---
  first_opposing = (0...texts.length).find do |i|
    !texts[i].nil? &&
    @battle.battlers[i].hp > 0 &&
    @battle.battlers[i].opposes?(@battle.battlers[idxBattler])
  end
  first_any = (0...texts.length).find do |i|
    !texts[i].nil? && @battle.battlers[i].hp > 0
  end
  @targetWindow.index = first_opposing || first_any || 0

  if @targetWindow.index == -1
    raise RuntimeError.new(_INTL("No targets somehow..."))
  end

  ret = -1
  pbSelectBattler((mode==0) ? @targetWindow.index : texts, 2)
  @targetWindow.showPlay

  loop do
    oldIndex = @targetWindow.index
    pbUpdate

    if mode == 0
      # --- LEFT/RIGHT NAVIGATION ---
      if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
        inc = ((@targetWindow.index % 2) == 0) ? -2 : 2
        inc *= -1 if Input.trigger?(Input::LEFT)
        indexLength = @battle.sideSizes[@targetWindow.index % 2] * 2
        newIndex = @targetWindow.index
        loop do
          newIndex += inc
          break if newIndex < 0 || newIndex >= indexLength
          next if texts[newIndex].nil? || @battle.battlers[newIndex].hp <= 0
          @targetWindow.index = newIndex
          break
        end

      # --- UP/DOWN NAVIGATION (row-aware) ---
      elsif Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
        current_row = @targetWindow.index % 2
        target_row = current_row ^ 1
        col_index = @targetWindow.index / 2
        found = false
        for i in 0...texts.length
          next if texts[i].nil? || @battle.battlers[i].hp <= 0
          if i % 2 == target_row && i / 2 == col_index
            @targetWindow.index = i
            found = true
            break
          end
        end
        # fallback: first alive in target row
        if !found
          for i in 0...texts.length
            next if texts[i].nil? || @battle.battlers[i].hp <= 0
            if i % 2 == target_row
              @targetWindow.index = i
              break
            end
          end
        end
      end

      # play select sound if changed
      if @targetWindow.index != oldIndex
        pbSEPlay("EBDX/SE_Select1")
        pbSelectBattler(@targetWindow.index)
      end
    end

    @targetWindow.update

    # --- CONFIRM SELECTION ---
    if Input.trigger?(Input::C)
      ret = @targetWindow.index
      pbSEPlay("EBDX/SE_Select1")
      break
    end

    # --- CANCEL ---
    if Input.trigger?(Input::B)
      ret = -1
      pbPlayCancelSE
      break
    end
  end

  self.pbDeselectAll(ret < 0 ? idxBattler : nil)
  @targetWindow.hidePlay
  @fightWindow.showPlay if ret < 0
  return ret
end

  #-----------------------------------------------------------------------------
end
