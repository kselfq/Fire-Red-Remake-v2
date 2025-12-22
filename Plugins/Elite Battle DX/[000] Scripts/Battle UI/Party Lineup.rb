#===============================================================================
#  Class to handle the construction and animation of opposing and player
#  party indicators (patched: simple swap player <-> opponent)
#===============================================================================
class PartyLineupEBDX
  attr_reader :loaded
  attr_accessor :toggle
  #-----------------------------------------------------------------------------
  def initialize(viewport, scene, battle, side)
    @viewport = viewport
    @scene = scene
    @sprites = @scene.sprites
    @battle = battle
    @side = side
    @num = Battle::Scene::NUM_BALLS
    @toggle = true
    @loaded = false
    @disposed = false
    @partyBar = pbBitmap("Graphics/EBDX/Pictures/UI/partyBar")
    @partyBalls = pbBitmap("Graphics/EBDX/Pictures/UI/partyBalls")
    @sprites["partyLine_#{@side}"] = Sprite.new(@viewport)
    @sprites["partyLine_#{@side}"].z = 99999
    for k in 0...@num
      @sprites["partyLine_#{@side}_#{k}"] = Sprite.new(@viewport)
      @sprites["partyLine_#{@side}_#{k}"].z = 99999
    end
  end
  #-----------------------------------------------------------------------------
  #  refresh both graphics and animation parameters
  #-----------------------------------------------------------------------------
  def refresh
    @toggle = true
    # get party details (keep original reversal logic)
    pty = self.party; pty.reverse! if (@side%2 == 1)
    # assign graphic and position party line
    @sprites["partyLine_#{@side}"].bitmap = @partyBar.clone
    # <-- swap the mirror/ox so the bar faces the other way -->
    @sprites["partyLine_#{@side}"].mirror = (@side%2 == 1)
    @sprites["partyLine_#{@side}"].ox = @side%2 == 1 ? @partyBar.width : 0
    @sprites["partyLine_#{@side}"].opacity = 255
    @sprites["partyLine_#{@side}"].zoom_x = 1
    # position party balls relative to main party line up
    for k in 0...@num
      @sprites["partyLine_#{@side}_#{k}"].bitmap = Bitmap.new(@partyBalls.height, @partyBalls.height)
      if pty[k].nil?
        pin = 3
      elsif pty[k].hp < 1 || pty[k].egg?
        pin = 2
      elsif EliteBattle.ShowStatusIcon(pty[k].status)
        pin = 1
      else
        pin = 0
      end
      @sprites["partyLine_#{@side}_#{k}"].bitmap.blt(0, 0, @partyBalls, Rect.new(@partyBalls.height*pin, 0, @partyBalls.height, @partyBalls.height))
      @sprites["partyLine_#{@side}_#{k}"].center!
      # <-- SWAPPED: moved player icons to left (side%2==0) and opponent to right -->
      @sprites["partyLine_#{@side}_#{k}"].ex = (@side%2 == 0 ? 12 : 26) + 24*k + @sprites["partyLine_#{@side}_#{k}"].ox
      @sprites["partyLine_#{@side}_#{k}"].ey = -12 + @sprites["partyLine_#{@side}_#{k}"].oy
      @sprites["partyLine_#{@side}_#{k}"].opacity = 255
      @sprites["partyLine_#{@side}_#{k}"].angle = 0
    end
    # <-- SWAPPED: start positions (player now starts off left, opponent off right) -->
    self.x = @side%2 == 0 ? (-@partyBar.width - 10) : (@viewport.width + @partyBar.width + 10)
    mult = (EliteBattle::USE_FOLLOWER_EXCEPTION && EliteBattle.follower(@battle).nil?) ? 0.65 : 0.5
    self.y = @side%2 == 0 ? @viewport.height*mult : @viewport.height*0.3
    @loaded = true
  end
  #-----------------------------------------------------------------------------
  def x=(val)
    @sprites["partyLine_#{@side}"].x = val
    for k in 0...@num
      @sprites["partyLine_#{@side}_#{k}"].x = @sprites["partyLine_#{@side}"].x + @sprites["partyLine_#{@side}_#{k}"].ex - @sprites["partyLine_#{@side}"].ox
    end
  end
  #-----------------------------------------------------------------------------
  def y=(val)
    @sprites["partyLine_#{@side}"].y = val
    for k in 0...@num
      @sprites["partyLine_#{@side}_#{k}"].y = @sprites["partyLine_#{@side}"].y + @sprites["partyLine_#{@side}_#{k}"].ey
    end
  end
  #-----------------------------------------------------------------------------
  def x; return @sprites["partyLine_#{@side}"].x; end
  def y; return @sprites["partyLine_#{@side}"].y; end
  #-----------------------------------------------------------------------------
  # <-- SWAPPED: end_x should match the new sides -->
  def end_x
    return @side%2 == 0 ? -10 : @viewport.width + 10
  end
  #-----------------------------------------------------------------------------
  def animating?
    return false if !@loaded
    return @side%2 == 0 ? (self.x < self.end_x) : (self.x > self.end_x) if @toggle
    return @sprites["partyLine_#{@side}"].opacity > 0 if !@toggle
    return false
  end
  #-----------------------------------------------------------------------------
  def update
    if !self.animating?
      for k in 0...@num
        @sprites["partyLine_#{@side}_#{k}"].angle = 0
      end
      return
    end
    # <-- SWAPPED: movement directions inverted to match new start/end -->
    if @toggle
      # move into position: player (side%2==0) moves right (positive), opponent moves left (negative)
      self.x += ((@partyBar.width/16)/self.delta) * (@side%2 == 0 ? 1 : -1)
      for k in 0...@num
        @sprites["partyLine_#{@side}_#{k}"].angle -= ((360/16) * (@side%2 == 0 ? 1 : -1))/self.delta
      end
    else
      @sprites["partyLine_#{@side}"].zoom_x += (1.0/16)/self.delta
      @sprites["partyLine_#{@side}"].opacity -= 24/self.delta
      for k in 0...@num
        m = @side%2 == 0 ? -k : (@num - k)
        @sprites["partyLine_#{@side}_#{k}"].angle -= ((360/16) * (@side%2 == 0 ? 1 : -1))/self.delta
        @sprites["partyLine_#{@side}_#{k}"].angle = 0 if @sprites["partyLine_#{@side}_#{k}"].angle >= 360 || @sprites["partyLine_#{@side}_#{k}"].angle <= -360
        @sprites["partyLine_#{@side}_#{k}"].opacity -= 24/self.delta
        @sprites["partyLine_#{@side}_#{k}"].x += (((@partyBar.width/16) * (@side%2 == 0 ? 1 : -1)) - m)/self.delta
      end
    end
  end
  #-----------------------------------------------------------------------------
  def party
    party = @battle.pbParty(@side).clone
    (@num - party.length).times { party.push(nil) }
    return party
  end
  #-----------------------------------------------------------------------------
  def delta; return Graphics.frame_rate/40.0; end
  def disposed?; return @disposed; end
  def dispose
    return if @disposed
    @partyBar.dispose
    @partyBalls.dispose
    @disposed = true
  end
end
#===============================================================================
#  Override standard party line up and replace with custom
#===============================================================================
class Battle::Scene
  alias pbShowPartyLineup_ebdx pbShowPartyLineup unless self.method_defined?(:pbShowPartyLineup_ebdx)
  def pbShowPartyLineup(side, fullAnim = false)
    if side%2 == 0
      @playerLineUp.refresh
    else
      @opponentLineUp.refresh
    end
  end
end
