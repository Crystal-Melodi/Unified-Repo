if !$PokemonSystem.nil?
  MKXP.puts("Executing Pokemon Essentials fixes")

  def getPlayTime(filename="")
    return 0
  end
  def set_loop_points(a="",b="")
  end
  #Keep default zoom at 0.5
  if defined?(SCREENDUALHEIGHT)
    DEFAULTSCREENZOOM = 1.0
  else
    DEFAULTSCREENZOOM = 0.5
  end
  begin
    oldvalue=$PokemonSystem.screensize
    $PokemonSystem.screensize=1
    if 1!=oldvalue
      pbSetResizeFactor(1.0)
      ObjectSpace.each_object(TilemapLoader){|o| next if o.disposed?; o.updateClass }
    end
  rescue
    MKXP.puts("Screen size could not set.")
  end

  #Graphics overrides
  module Graphics
    def self.width
      return Graphics.poke_width.to_i
    end

    def self.height
      return Graphics.poke_height.to_i
    end

    def self.haveresizescreen
      return true
    end

    def self.snap_to_bitmap
      return Graphics.poke_snap_to_bitmap
    end

    def self.resize_screen(w,h)
      @@width=w
      @@height=h
      Graphics.poke_resize_screen(w,h)
    end
  end

  #Fixes for Green Remix
  module Downloader
    def self.downloading?
      return false
    end
    def self.update
    end
    def self.progress?
      return 100
    end
    def self.download(url, filename)
    end
    def self.createIfNecessary(filename)
    end
    def self.finishUp
    end
    def self.startNext
    end
  end
  module Berka
    module NetErrorErr
      ConIn="Unable to connect to Internet"
      ConFtp="Unable to connect to Ftp"
      ConHttp="Unable to connect to the Server"
      NoFFtpIn="The file to be downloadeded doesn't exist"
      NoFFtpEx="The file to be upload doesn't exist"
      TranHttp="Http Download failed"
      DownFtp="Ftp Download  failed"
      UpFtp="Ftp Upload failed"
      NoFile="No file to be downloaded"
      Mkdir="Unable to create a new directory"
    end
  end

  class PokemonEntryScene
    USEKEYBOARD = (defined?(DexObtained) == 'constant' && DexObtained.class == Class)
  end

  #Fix loadSkinFile for Pyrite
  class SpriteWindow
    def loadSkinFile(file)
      if (self.windowskin.width==80 || self.windowskin.width==96) &&
        self.windowskin.height==48
        # Body = X, Y, width, height of body rectangle within windowskin
        @skinrect.set(32,16,16,16)
        # Trim = X, Y, width, height of trim rectangle within windowskin
        @trim=[32,16,16,16]
      elsif self.windowskin.width==80 && self.windowskin.height==80
        @skinrect.set(32,32,16,16)
        @trim=[32,16,16,48]
      end
    end
  end

  #Fix Challenge Run options
  class ControlWindow
    def initialize(x,y,width,height)
      super(x,y,width,height)
      self.contents=Bitmap.new(width-32,height-32)
      pbSetNarrowFont(self.contents)
      @controls=[]
      @aindex = 0
    end
    def update
      super
      if Input.trigger?(Input::DOWN)
        @aindex = @aindex + 1
        @aindex = 0 if @aindex >= @controls.length
      elsif Input.trigger?(Input::UP)
        @aindex = @aindex - 1
        @aindex = @controls.length -1 if @aindex < 0
      elsif Input.trigger?(Input::LEFT)
        control = @controls[@aindex]
        if control.is_a? Checkbox
          control.checked = true
        end
      elsif Input.trigger?(Input::RIGHT)
        control = @controls[@aindex]
        if control.is_a? Checkbox
          control.checked = false
        end
      end
      for i in 0...@controls.length
        @controls[i].update
      end
      repaint
    end
  end

  def autosave
  end

  begin
    class Game_Player
      alias cheatPassable? passable? unless self.method_defined?(:cheatPassable?)
      def passable?(x, y, d)
        if $wtw
          return true
        else
          cheatPassable?(x, y, d)
        end
      end
    end
  rescue
    MKXP.puts("Could not override Game_Map::playerPassable")
  end

  #Natural Green Fixes
  def pbGetTextFromInternet(url)
    return ""
  end

  #Don't try to install fonts
  module FontInstaller
    def self.install
    end
  end

  module ADIK
    module DATA
    DATA_PATH = 'CURRENT'
    FOLDER = []
    FILENAME = "gjdata.data"
  	AUTOSAVE = false
    end
  end

  module GameJolt
    @status = -1

    def self.login()
      return -1
    end

    def self.login()
      return true
    end

    def self.login_status
      return @status
    end

    def self.reset_status
      @status = -1
    end

    def self.is_logged_in()
      return false
    end

    def self.has_already_got_trophy?(trophy_id)
      return false
    end

    def self.award_trophy(trophy_id)
    end

    def self.submit_score(score, score_description = "(SCORE) point(SCOREPLURAL)", scoreboard_id = "main", extra_data = "", allow_guests = false, guest_name = "")
      return false
    end

    def self.show_highscores(numberofscores = 4, scoreboard_id = "main")
    end

    def self.call()
      return self.login()
    end

    def self.logoff()
      @status = -1
      $user = nil
      $password = nil
    end

    # Internal vars
    @error = ""

    # Internal functions (you can use these if you need, but you'll want to use
    # the functions above most of the time)
    def self.do_request(baseUrl)
      return {"success" => "false"}
    end

    def self.make_bool(string)
      return string == "true"
    end

    def self.authenticate(username, token)
      return true
    end

    def self.get_userdata_string()
    end

    def self.get_error()
      return @error
    end

    def self.sync_trophies()
    end

    def self.get_highscores_formatted(numberofscores = 10, scoreboard_id = "main")
      return ""
    end

    def self.get_highscores(numberofscores = 10, scoreboard_id = "main", user_only = false)
      return nil
    end

    def self.has_login_data()
      return "JoiPlay"
    end

    def self.enter_text(text="", var=Tsuki::Text_Input::Text_Variable, max_char=Tsuki::Text_Input::Max_Chars)
      $inputText = pbEnterText(text,0,30,"", 3, nil)
    end
  end

  MKXP.puts("Pokemon Essentials fixes are executed.")
end