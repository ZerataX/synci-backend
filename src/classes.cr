require "json"

class OutOfBounds < Exception
end

class Song
  include JSON::Serializable
  getter id : String
  getter name : String
  getter length : Int32
  getter artist : String | Nil
  getter image : String | Nil

  def initialize(@id, @name, @length = 0, @artist = nil, @image = nil)
  end
end
  
class User
  include JSON::Serializable
  setter name : String
  getter host : Bool
  setter image : String | Nil
  setter url : String | Nil

  def initialize(@name, @host = false, @image = nil, @url = nil)
  end
end

class Player
  include JSON::Serializable
  getter currentSong : Song | Nil
  getter playing : Bool
  getter timecode : Int32
  getter index : Int32
  property queue : Array(User)

  def initialize()
    @currentSong = nil
    @playing = false
    @index = 0
    @timecode = 0
    @queue = [] of User
  end

  def play()
    @playing = true
  end

  def pause()
    @playing = false
  end

  def seek(timecode : Int32)
    if currentSong.not_nil!.length < timecode
      raise OutOfBounds.new("The current song is not that long")
    else
      @timecode = timecode
    end
  end

  def next()
    if @index + 1 < queue.size
      @index += 1
    else
      raise OutOfBounds.new("There's no next song")
    end
  end

  def previous()
    if @index - 1 < queue.size
      @index -= 1
    else
      raise OutOfBounds.new("There's no previous song")
    end
  end
end