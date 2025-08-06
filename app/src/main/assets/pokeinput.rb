if !$PokemonSystem.nil?
  # Override Input module to support controllers
  module Input

    def self.update
      self.jupdate
    end
    def self.dir4
      return self.jdir4
    end
    def self.dir8
      return self.jdir8
    end
    def self.trigger?(button)
      return self.jtrigger?(button)
    end

    def self.repeat?(button)
      return self.jrepeat?(button)
    end

    def self.press?(button)
      return self.jpress?(button)
    end

    def self.release?(button)
      return self.asyncKeyState(button) > 0
    end

    def self.releaseex?(key)
      return self.asyncKeyState(key) > 0
    end

    def self.repeatex?(key)
      return self.jrepeatex?(key)
    end

    def self.triggerex?(key)
      return self.jtriggerex?(key)
    end

    def self.pressex?(key)
      return self.jpressex?(key)
    end

    def self.repeatcount(key)
      return 0
    end

    def self.updateKeyState(key)
    end
  end
end