#===============================================================================
#  Command Choices
#  UI overhaul
#===============================================================================
class ChoiceWindowEBDX
  attr_accessor :index
  attr_reader :over
  #-----------------------------------------------------------------------------
  #  initialize the choice boxes
  #-----------------------------------------------------------------------------
  def initialize(viewport,commands,scene)
    @commands = commands
    @scene = scene
    @index = 0
    @path = "Graphics/EBDX/Pictures/UI/"
    @viewport = viewport
    @sprites = {}
    @visibility = [false,false,false,false]

    # apply styling from PBS
    self.applyMetrics

    # global offsets
    @global_offset_x = 0
    @global_offset_y = 0

    # create single arrow cursor
    @sprites["sel"] = Sprite.new(@viewport)
    @sprites["sel"].bitmap = pbBitmap(@path + "arrow")
    @sprites["sel"].ox = @sprites["sel"].bitmap.width / 2
    @sprites["sel"].oy = @sprites["sel"].bitmap.height / 2
    @sprites["sel"].z = 99999
    @sprites["sel"].visible = false

    # bouncing variables
    @sel_dir = 1
    @sel_speed = 1
    @sel_max = 4
    @sel_offset = 0

    # manual arrow x offset
    @arrow_x_offset = -82

    # create buttons with bottom alignment
    base_bmp = pbBitmap(@path + @btnImg)
    button_height = base_bmp.height
    button_spacing = 4
    total_height = @commands.length * (button_height + button_spacing) - button_spacing
    # 12 px from bottom
    start_y = Graphics.height - 16 - total_height + button_height / 2

    for i in 0...@commands.length
      k = i
      @sprites["choice#{i}"] = Sprite.new(@viewport)
      @sprites["choice#{i}"].x = Graphics.width - base_bmp.width - 16 + base_bmp.width / 2 + @global_offset_x
      @sprites["choice#{i}"].y = start_y + k * (button_height + button_spacing) + @global_offset_y
      @sprites["choice#{i}"].z = 99998
      @sprites["choice#{i}"].bitmap = Bitmap.new(base_bmp.width, button_height)
      @sprites["choice#{i}"].center!
      @sprites["choice#{i}"].opacity = 0
    end
    base_bmp.dispose

    refresh_all_buttons
  end

  #-----------------------------------------------------------------------------
  def applyMetrics
    @btnImg = "btnEmpty"
    @selImg = "cmdSel"
    d1 = EliteBattle.get(:nextUI)
    d1 = d1[:CHOICE_MENU] if !d1.nil? && d1.has_key?(:CHOICE_MENU)
    d2 = EliteBattle.get_data(:CHOICE_MENU, :Metrics, :METRICS)
    for data in [d2, d1]
      next if data.nil?
      @btnImg = data[:BUTTONS] if data.has_key?(:BUTTONS) && data[:BUTTONS].is_a?(String)
      @selImg = data[:SELECTOR] if data.has_key?(:SELECTOR) && data[:SELECTOR].is_a?(String)
    end
  end

  #-----------------------------------------------------------------------------
  def dispose(scene)
    2.times do
      @sprites["sel"].opacity -= 128
      for i in 0...@commands.length
        @sprites["choice#{i}"].opacity -= 128
      end
      scene.animateScene(true)
      scene.pbGraphicsUpdate
    end
    pbDisposeSpriteHash(@sprites)
  end

  #-----------------------------------------------------------------------------
  def refresh_button(i)
    bmp_graphic = pbBitmap(@path + (i == @index ? "btnChoose" : "btnEmpty"))
    @sprites["choice#{i}"].bitmap.blt(0, 0, bmp_graphic, bmp_graphic.rect)
    bmp_graphic.dispose

    text_color = (i == @index ? Color.black : Color.black)
    pbSetSystemFont(@sprites["choice#{i}"].bitmap)
    pbDrawOutlineText(@sprites["choice#{i}"].bitmap, 0, 8, @sprites["choice#{i}"].bitmap.width, @sprites["choice#{i}"].bitmap.height, @commands[i], text_color, Color.new(0,0,0,0), 1)
  end

  def refresh_all_buttons
    for i in 0...@commands.length
      refresh_button(i)
    end
  end

  #-----------------------------------------------------------------------------
  def update
    oldIndex = @index

    if Input.trigger?(Input::UP)
      pbSEPlay("EBDX/SE_Select1")
      @index -= 1
      @index = @commands.length - 1 if @index < 0
    elsif Input.trigger?(Input::DOWN)
      pbSEPlay("EBDX/SE_Select1")
      @index += 1
      @index = 0 if @index >= @commands.length
    end

    refresh_button(oldIndex) if oldIndex != @index
    refresh_button(@index) if oldIndex != @index

    # update arrow position
    base_x = @sprites["choice#{@index}"].x + @global_offset_x
    @sprites["sel"].y = @sprites["choice#{@index}"].y - 2 + @global_offset_y
    @sel_offset += @sel_speed * @sel_dir
    @sel_dir *= -1 if @sel_offset.abs >= @sel_max
    @sprites["sel"].x = base_x + @sel_offset + @arrow_x_offset
    @sprites["sel"].visible = true

    # animate button fade-in
    for i in 0...@commands.length
      @sprites["choice#{i}"].opacity += 128 if @sprites["choice#{i}"].opacity < 255
      @sprites["choice#{i}"].src_rect.y += 1 if @sprites["choice#{i}"].src_rect.y < 0
    end
  end

  def shiftMode=(val); end
end
