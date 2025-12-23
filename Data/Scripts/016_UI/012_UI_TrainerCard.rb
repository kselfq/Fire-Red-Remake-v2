#===============================================================================
#
#===============================================================================
class PokemonTrainerCard_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    background = pbResolveBitmap("Graphics/UI/Trainer Card/bg_f")
    if $player.female? && background
      addBackgroundPlane(@sprites, "bg", "Trainer Card/bg_f", @viewport)
    else
      addBackgroundPlane(@sprites, "bg", "Trainer Card/bg", @viewport)
    end
    cardexists = pbResolveBitmap(_INTL("Graphics/UI/Trainer Card/card_f"))
    @sprites["card"] = IconSprite.new(0, 0, @viewport)
    if $player.female? && cardexists
      @sprites["card"].setBitmap(_INTL("Graphics/UI/Trainer Card/card_f"))
    else
      @sprites["card"].setBitmap(_INTL("Graphics/UI/Trainer Card/card"))
    end
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["trainer"] = IconSprite.new(422, 134, @viewport)
    @sprites["trainer"].setBitmap(GameData::TrainerType.player_front_sprite_filename($player.trainer_type))
    @sprites["trainer"].x -= (@sprites["trainer"].bitmap.width - 128) / 2
    @sprites["trainer"].y -= (@sprites["trainer"].bitmap.height - 128)
    @sprites["trainer"].z = 2
    pbDrawTrainerCardFront
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor   = Color.new(72, 72, 72)
    shadowColor = Color.new(192, 32, 40, 0)
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = (hour > 0) ? _INTL("{1}h {2}m", hour, min) : _INTL("{1}m", min)
    $PokemonGlobal.startTime = Time.now if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
                      pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
                      $PokemonGlobal.startTime.day,
                      $PokemonGlobal.startTime.year)
    textPositions = [
      [_INTL("Name"), 132, 97, :left, baseColor, shadowColor],
      [$player.name, 384, 97, :right, baseColor, shadowColor],
      [_INTL("ID No."), 426, 97, :left, baseColor, shadowColor],
      [sprintf("%05d", $player.public_ID), 546, 97, :right, baseColor, shadowColor],
      [_INTL("Money"), 132, 145, :left, baseColor, shadowColor],
      [_INTL("${1}", $player.money.to_s_formatted), 384, 145, :right, baseColor, shadowColor],
      [_INTL("Pokédex"), 132, 193, :left, baseColor, shadowColor],
      [sprintf("%d/%d", $player.pokedex.owned_count, $player.pokedex.seen_count), 384, 193, :right, baseColor, shadowColor],
      [_INTL("Time"), 132, 241, :left, baseColor, shadowColor],
      [time, 384, 241, :right, baseColor, shadowColor],
      [_INTL("Started"), 132, 289, :left, baseColor, shadowColor],
      [starttime, 384, 289, :right, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)
region = pbGetCurrentRegion(0)

start_x = 599
start_y = 26

cols = 2
spacing_x = 86   # >= 74
spacing_y = 86

badge_bitmap = Bitmap.new("Graphics/UI/Trainer Card/icon_badges")

8.times do |i|
  next if !$player.badges[i + (region * 8)]

  col = i % cols
  row = i / cols

  x = start_x + (col * spacing_x)
  y = start_y + (row * spacing_y)

  src_rect = Rect.new(
    i * 74,          # badge column in spritesheet
    region * 74,     # badge row (region)
    74, 74
  )

  overlay.blt(x, y, badge_bitmap, src_rect)
end

badge_bitmap.dispose

  end

  def pbTrainerCard
    pbSEPlay("GUI trainer card open")
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonTrainerCardScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end
