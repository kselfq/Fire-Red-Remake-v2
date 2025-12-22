#===============================================================================
#  Fight Menu functionality part
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  #  main fight menu override
  #-----------------------------------------------------------------------------
  def pbFightMenu(idxBattler, megaEvoPossible = false)
    battler = @battle.battlers[idxBattler]
    self.clearMessageWindow
    @fightWindow.battler = battler
    @fightWindow.refreshMegaButton

    moveIndex = 0
    if battler.moves[@lastMove[idxBattler]] && battler.moves[@lastMove[idxBattler]].id
      moveIndex = @lastMove[idxBattler]
    end
    @fightWindow.index = (battler.moves[moveIndex].id != 0) ? moveIndex : 0

    @fightWindow.generateButtons
    @sprites["dataBox_#{idxBattler}"].selected = true
    pbSEPlay("EBDX/SE_Zoom4", 50)
    @fightWindow.showPlay

    loop do
      oldIndex = @fightWindow.index
      self.updateWindow(@fightWindow)

      if Input.trigger?(Input::UP)
        @fightWindow.index -= 1
        @fightWindow.index = @fightWindow.nummoves - 1 if @fightWindow.index < 0
      elsif Input.trigger?(Input::DOWN)
        @fightWindow.index += 1
        @fightWindow.index = 0 if @fightWindow.index >= @fightWindow.nummoves
      end

      pbSEPlay("EBDX/SE_Select1") if @fightWindow.index != oldIndex

      if Input.trigger?(Input::C)
        pbSEPlay("EBDX/SE_Select2")
        break if yield @fightWindow.index
      elsif Input.trigger?(Input::B)
        pbPlayCancelSE
        break if yield -1
      elsif Input.trigger?(Input::A)
        if megaEvoPossible
          @fightWindow.megaButtonTrigger
          pbSEPlay("DX Action Button")
        end
        break if yield -2
      end
    end

    self.pbResetParams if @ret > -1
    @fightWindow.hidePlay
    self.pbDeselectAll
    @lastMove[idxBattler] = @fightWindow.index
  end
  #-----------------------------------------------------------------------------
end

#===============================================================================
#  Fight Menu (Next Generation)
#===============================================================================
class FightWindowEBDX
  attr_accessor :index
  attr_accessor :battler
  attr_accessor :refreshpos
  attr_reader :nummoves

  #-----------------------------------------------------------------------------
  def refreshMegaButton
    # Ensure per-battle "mega used" flag exists (do not modify other code)
    if @battle && !@battle.instance_variable_defined?(:@ebdx_mega_used)
      @battle.instance_variable_set(:@ebdx_mega_used, false)
    end

    if @battler && @battle
      can_mega = @battle.pbCanMegaEvolve?(@battle.battlers.index(@battler))
      used = @battle.instance_variable_get(:@ebdx_mega_used) rescue false
      # Only show Mega if Pokémon can mega, hasn't already mega'd, and no other Pokémon used mega this battle
      @showMega = can_mega && !@battler.mega? && !used
      @megaButton.visible = @showMega
    else
      @showMega = false
      @megaButton.visible = false
    end
  end
  #-----------------------------------------------------------------------------
  def inspect
    str = self.to_s.chop
    str << format(' index: %s>', @index)
    return str
  end
  #-----------------------------------------------------------------------------
  def initialize(viewport = nil, battle = nil, scene = nil)
    @viewport = viewport
    @battle = battle
    @scene = scene
    @index = 0
    @oldindex = -1
    @over = false
    @refreshpos = false
    @battler = nil
    @nummoves = 0

    @path = "Graphics/EBDX/Pictures/UI/"
    self.applyMetrics

    @buttonBitmap = pbBitmap(@path + @cmdImg)
    
    lang = pbGetSelectedLanguage
    typeBitmapPath = pbResolveBitmap("Graphics/EBDX/Pictures/UI/types_"+lang)
    @typebitmap = typeBitmapPath ? pbBitmap(typeBitmapPath) : pbBitmap(@path + @typImg)
    @typebitmap = pbBitmap("Graphics/EBDX/Pictures/UI/types") if !@typebitmap
    @catBitmap = pbBitmap(@path + @catImg)

    @background = Sprite.new(@viewport)
    @background.create_rect(@viewport.width,64,Color.new(0,0,0,0))
    @background.bitmap = pbBitmap(@path + @barImg) if !@barImg.nil?
    @background.y = Graphics.height - @background.bitmap.height
    @background.z = 100

    @megaButton = Sprite.new(@viewport)
    @megaButton.bitmap = pbBitmap(@path + @megaImg)
    @megaButton.z = 101
    @megaButton.src_rect.width /= 2
    @megaButton.center!
    @megaButton.x = 556
    @megaButton.y = 334

    @sel = Sprite.new(@viewport)
    @sel.bitmap = pbBitmap(@path + "arrow")
    @sel.ox = @sel.bitmap.width / 2
    @sel.oy = @sel.bitmap.height / 2
    @sel.z = 199
    @sel.visible = true
    @sel_bounce_x = 0
    @sel_bounce_dir = 1
    @sel_bounce_speed = 1
    @sel_bounce_limit = 3

    @button = {}
    @moved = false
    @showMega = false

    eff = [_INTL("Normal damage"),_INTL("Not very effective"),_INTL("Super effective"),_INTL("No effect")]
    @typeInd = Sprite.new(@viewport)
    @typeInd.bitmap = Bitmap.new(228,24*4)
    pbSetSmallFont(@typeInd.bitmap)
    for i in 0...4
      pbDrawOutlineText(@typeInd.bitmap,0,24*i + 5,228,24,eff[i],Color.white,Color.new(0,0,0,0),1)
    end
    @typeInd.src_rect.set(0,0,228,24)
    @typeInd.ox = 228/2
    @typeInd.oy = 16
    @typeInd.z = 200
    @typeInd.visible = false
  end

  #-----------------------------------------------------------------------------
  def applyMetrics
    @cmdImg = "moveSelButtons"
    @selImg = "cmdSel"
    @typImg = "types"
    @catImg = "category"
    @megaImg = "megaButton"
    @barImg = nil
    @showTypeAdvantage = false
    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:FIGHTMENU] if d1 && d1.has_key?(:FIGHTMENU)
    d2 = EliteBattle.get_data(:FIGHTMENU, :Metrics, :METRICS)
    d7 = EliteBattle.get_map_data(:FIGHTMENU_METRICS)
    d6 = @battle.opponent ? EliteBattle.get_trainer_data(@battle.opponent[0].trainer_type, :FIGHTMENU_METRICS, @battle.opponent[0]) : nil
    d5 = !@battle.opponent ? EliteBattle.get_data(@battle.battlers[1].species, :Species, :FIGHTMENU_METRICS, (@battle.battlers[1].form rescue 0)) : nil
    for data in [d2, d7, d6, d5, d1]
      next if data.nil?
      @megaImg = data[:MEGABUTTONGRAPHIC] if data.has_key?(:MEGABUTTONGRAPHIC) && data[:MEGABUTTONGRAPHIC].is_a?(String)
      @cmdImg = data[:BUTTONGRAPHIC] if data.has_key?(:BUTTONGRAPHIC) && data[:BUTTONGRAPHIC].is_a?(String)
      @selImg = data[:SELECTORGRAPHIC] if data.has_key?(:SELECTORGRAPHIC) && data[:SELECTORGRAPHIC].is_a?(String)
      @barImg = data[:BARGRAPHIC] if data.has_key?(:BARGRAPHIC) && data[:BARGRAPHIC].is_a?(String)
      @typImg = data[:TYPEGRAPHIC] if data.has_key?(:TYPEGRAPHIC) && data[:TYPEGRAPHIC].is_a?(String)
      @catImg = data[:CATEGORYGRAPHIC] if data.has_key?(:CATEGORYGRAPHIC) && data[:CATEGORYGRAPHIC].is_a?(String)
      @showTypeAdvantage = data[:SHOWTYPEADVANTAGE] if data.has_key?(:SHOWTYPEADVANTAGE)
    end
  end

  #-----------------------------------------------------------------------------
  
def generateButtons
  @moves = @battler.moves
  @x = []; @y = []
  @nummoves = 0

  for i in 0...4
    @button[i.to_s]&.dispose
    @nummoves += 1 if @moves[i] && @moves[i].id
  end

  # --- BOTTOM-UP BUTTON POSITIONS WITH 16px MARGIN ---
  margin_x = 16
  margin_y = 16
  manual_offset_y = -36
  spacing = 40
  for i in 0...@nummoves
    @x[i] = @viewport.width - margin_x
    # Start from bottom, each button above previous
    @y[i] = @viewport.height - margin_y - (@nummoves - i - 1) * spacing + manual_offset_y
  end

  for i in 0...@nummoves
    movedata = GameData::Move.get(@moves[i].id)
    category = movedata.physical? ? 0 : (movedata.special? ? 1 : 2)
    type = GameData::Type.get(movedata.type).icon_position

    @button[i.to_s] = Sprite.new(@viewport)
    @button[i.to_s].param = category
    @button[i.to_s].z = 82
    @button[i.to_s].bitmap = Bitmap.new(228*2,38)
    @button[i.to_s].bitmap.blt(0,0,@buttonBitmap,Rect.new(0,type*38,228,38))
    #@button[i.to_s].bitmap.blt(138,8,@catBitmap,Rect.new(0,category*22,38,22))
    @button[i.to_s].bitmap.blt(3,46,@typebitmap,Rect.new(0,type*22,72,22))

    pbSetSmallFont(@button[i.to_s].bitmap) # small font for moves names
    text = [[movedata.name,36,12,10,Color.black,Color.new(0,0,0,0)]]
    pbDrawTextPositions(@button[i.to_s].bitmap,text)

    pp = "#{@moves[i].pp}/#{@moves[i].total_pp}"
    pbDrawOutlineText(@button[i.to_s].bitmap,-8,12,228,38,pp,Color.white,Color.new(0,0,0,0),2)

    @button[i.to_s].src_rect.set(0,0,228,38)
    @button[i.to_s].ox = 228
    @button[i.to_s].x = @x[i]
    @button[i.to_s].y = @y[i]
    @button[i.to_s].visible = true # ensures buttons always visible
  end
end

  
  #-----------------------------------------------------------------------------
  def show
    @sel.visible = false
    @typeInd.visible = false
    @background.y -= (@background.bitmap.height/8)
    # Restore button positions and visibility (BEST VERSION)
    for i in 0...@nummoves
      @button[i.to_s].x = @x[i]
      @button[i.to_s].y = @y[i]
      @button[i.to_s].visible = true
    end
  end

  def showPlay
    @megaButton.src_rect.x = 0
    @megaButton.y = 334
    8.times do
      self.show; @scene.wait(1, true)
    end
  end

  def hide
    @sel.visible = false
    @typeInd.visible = false
    @background.y += (@background.bitmap.height/8)
    @megaButton.y = @viewport.height - @background.bitmap.height/2 + 100
    for i in 0...@nummoves
      @button[i.to_s].x = -200
      @button[i.to_s].visible = false
    end
    @showMega = false
    @megaButton.src_rect.x = 0
  end

  def hidePlay
    8.times do
      self.hide; @scene.wait(1, true)
    end
    @megaButton.y = @viewport.height - @background.bitmap.height/2 + 100
  end

  def megaButton
    @showMega = true
  end

  def megaButtonTrigger
    # original visual toggle
    @megaButton.src_rect.x += @megaButton.src_rect.width
    @megaButton.src_rect.x = 0 if @megaButton.src_rect.x > @megaButton.src_rect.width
    @megaButton.src_rect.y = -4
    # mark that a mega evolution has been used this battle (prevents other pokémon from showing the mega button)
    if @battle
      @battle.instance_variable_set(:@ebdx_mega_used, true)
    end
  end

  def update
    @sel.visible = true

    if @showMega
      @megaButton.y -= 10 if @megaButton.y > @viewport.height - @background.bitmap.height / 2
      @megaButton.src_rect.y += 1 if @megaButton.src_rect.y < 0
    end

    if @oldindex != @index
      @oldindex = @index
      if @showTypeAdvantage && !(@battle.doublebattle? || @battle.triplebattle?)
        move = @battler.moves[@index]
        @modifier = move.pbCalcTypeMod(move.type, @player, @opponent)
      end
    end

    @sel.x = @button["#{@index}"].x - 228
    @sel.y = @button["#{@index}"].y + 20
    @sel_bounce_x ||= 0
    @sel_bounce_dir ||= 1
    @sel_bounce_speed ||= 1
    @sel_bounce_limit ||= 4
    @sel_bounce_x += @sel_bounce_dir * @sel_bounce_speed
    @sel_bounce_dir *= -1 if @sel_bounce_x > @sel_bounce_limit || @sel_bounce_x < -@sel_bounce_limit
    @sel.x += @sel_bounce_x
    @sel.update

    if @showTypeAdvantage && !(@battle.doublebattle? || @battle.triplebattle?)
      @typeInd.visible = true
      @typeInd.y = @button["#{@index}"].y
      @typeInd.x = @button["#{@index}"].x
      eff = 0
      if @button["#{@index}"].param == 2
        eff = 4
      elsif @modifier == 0
        eff = 3
      elsif @modifier < 8
        eff = 1
      elsif @modifier > 8
        eff = 2
      end
      @typeInd.src_rect.y = 24 * eff
    end
  end

  #-----------------------------------------------------------------------------
  def dispose
    @buttonBitmap.dispose
    @catBitmap.dispose
    @typeBitmap.dispose if @typeBitmap
    @background.dispose
    @megaButton.dispose
    @typeInd.dispose
    pbDisposeSpriteHash(@button)
  end
end
