#===============================================================================
# Custom Message Box Position – Final Patch (Arrow absolute positioning option)
# For Pokémon Essentials 21.1 + EBDX (Unofficial)
# - skin1 (498x82) => bottom-left
# - skin2 (512x94) => centered horizontally, 12px from bottom
# - Per-skin text area + arrow position (arrow can be absolute or relative)
#===============================================================================

module CustomMessageBoxPosition
  # ----------------- CONFIG -----------------
  # Edit these values to fine-tune positions and text areas for each skin.
  # arrow_mode: :absolute -> arrow_x/arrow_y are screen coordinates
  #             :relative -> arrow_x/arrow_y are offsets from box top-left
  CONFIG = {
    skin1: {
      box_file:   "Graphics/EBDX/Pictures/UI/skin1",  # expected 498x82
      box_width:  498,
      box_height: 82,
      text_x:     0,    # offset inside the box (from left edge of box)
      text_y:     -8,     # offset inside the box (from top of box)
      text_width: 498 - 32,
      text_height: 102,    # height that fits ~2 lines (adjust if needed)
      arrow_mode: :absolute,
      arrow_x:    600,   # ABSOLUTE screen X for pause arrow (change to suit)
      arrow_y:    400    # ABSOLUTE screen Y for pause arrow (change to suit)
    },
    skin2: {
      box_file:   "Graphics/EBDX/Pictures/UI/skin2",  # expected 512x94
      box_width:  512,
      box_height: 94,
      text_x:     16,
      text_y:     0,
      text_width: 512 - 16,
      text_height: 114,
      arrow_mode: :absolute,
      arrow_x:    880,   # ABSOLUTE screen X for skin2 arrow (tweak)
      arrow_y:    400    # ABSOLUTE screen Y for skin2 arrow (tweak)
    }
  }
  # -------------------------------------------

  # ----------------- pbSetMessageMode -----------------
  def pbSetMessageMode(mode, light = false)
    super if defined?(super)
    box  = @sprites["messageBox"] rescue nil
    text = @sprites["messageWindow"] rescue nil
    return if !box || !text

    @messageSkin = light ? :skin2 : :skin1
    cfg = CONFIG[@messageSkin] || CONFIG[:skin1]

    begin
      bmp = Bitmap.new(cfg[:box_file])
      box.bitmap = bmp
      box.src_rect.set(0, 0, bmp.width, bmp.height)
    rescue StandardError => e
      Graphics.debug_puts("CustomMessageBoxPosition: Failed to load #{cfg[:box_file]} (#{e.message})") if defined?(Graphics) && Graphics.respond_to?(:debug_puts)
    end

    applyMessageBoxPosition(box, text)

    text.x      = box.x + cfg[:text_x]
    text.y      = box.y + cfg[:text_y]
    text.width  = cfg[:text_width]
    text.height = cfg[:text_height]
    text.letterbyletter = true
    text.refresh if text.respond_to?(:refresh)

    applyPauseArrowPosition(box, text)
  end
  # ----------------------------------------------------

  # ----------------- pbShowWindow -----------------
  def pbShowWindow(*args)
    super(*args) if defined?(super)
    box  = @sprites["messageBox"] rescue nil
    text = @sprites["messageWindow"] rescue nil
    if box && text
      applyMessageBoxPosition(box, text)
      cfg = CONFIG[@messageSkin] || CONFIG[:skin1]
      text.x      = box.x + cfg[:text_x]
      text.y      = box.y + cfg[:text_y]
      text.width  = cfg[:text_width]
      text.height = cfg[:text_height]
      text.refresh if text.respond_to?(:refresh)
      applyPauseArrowPosition(box, text)
    end
  end
  # ------------------------------------------------

  # ----------------- applyMessageBoxPosition -----------------
  def applyMessageBoxPosition(box, text)
    return if !box || !text
    cfg = CONFIG[@messageSkin] || CONFIG[:skin1]

    case @messageSkin
    when :skin1
      box.x = 0
      box.y = @viewport.height - box.bitmap.height
    when :skin2
      box.x = (@viewport.width - box.bitmap.width) / 2
      box.y = @viewport.height - box.bitmap.height - 12
    else
      box.x = (@viewport.width - box.bitmap.width) / 2
      box.y = @viewport.height - box.bitmap.height
    end

    text.x = box.x + cfg[:text_x]
    text.y = box.y + cfg[:text_y]
  end
  # ------------------------------------------------------------

  # ----------------- applyPauseArrowPosition -----------------
  # Now supports absolute or relative modes.
  # If arrow_mode == :absolute -> arrow_x/arrow_y are screen coordinates.
  # If arrow_mode == :relative -> arrow_x/arrow_y are offsets from box top-left.
  def applyPauseArrowPosition(box, text)
    return if !text
    cfg = CONFIG[@messageSkin] || CONFIG[:skin1]

    # get arrow sprite from common instance vars
    arrow = nil
    if text.instance_variable_defined?(:@cursorSprite)
      arrow = text.instance_variable_get(:@cursorSprite)
    elsif text.instance_variable_defined?(:@pauseSprite)
      arrow = text.instance_variable_get(:@pauseSprite)
    end
    return if !arrow

    if cfg[:arrow_mode] == :absolute
      # Absolute screen coordinates
      # (You can set these values in CONFIG to anywhere on screen)
      arrow.x = cfg[:arrow_x] || arrow.x
      arrow.y = cfg[:arrow_y] || arrow.y
    else
      # Relative to the message box top-left
      arrow.x = box.x + (cfg[:arrow_x] || 0)
      arrow.y = box.y + (cfg[:arrow_y] || 0)
    end
  end
  # ------------------------------------------------------------
end

class Battle::Scene
  prepend CustomMessageBoxPosition
end

#===============================================================================
# Installation:
# - Save as Plugins/[000] Scripts/Custom Message Box Position.rb
# - Ensure PNGs exist:
#     Graphics/EBDX/Pictures/UI/skin1.png   (498x82)
#     Graphics/EBDX/Pictures/UI/skin2.png   (512x94)
# - Tune arrow_x/arrow_y values in CONFIG for absolute positioning.
#===============================================================================
