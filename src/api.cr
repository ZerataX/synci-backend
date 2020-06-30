require "kemal"
require "./classes"

song = Song.new id: "spotify:track:2mlGPkAx4kwF8Df0GlScsC", name: "Buttercup", length: 3600, image: "https://i.scdn.co/image/ab67616d00001e02affdacd1466cdde505ab97ee"
user = User.new "Mojibake", false, "https://i.scdn.co/image/ab6775700000ee855fdae9b1acbbd7a3d09e4200", "https://open.spotify.com/user/icrxkcxt7hg47exe6emo6g3r7"
player = Player.new
queue = [] of Song
users = [] of User

before_all do |env|
  env.response.content_type = "application/json"
end

get "/session/:name" do |env|
  name = env.params.url["name"]
  {name: name}.to_json
end

get "/session/:name/queue" do |env|
  name = env.params.url["name"]
  {songs: queue}.to_json
end

post "/session/:name/queue" do |env|
  name = env.params.url["name"]
  begin
    song = Song.from_json env.params.json.to_json
    song.to_json  
  rescue ex : JSON::ParseException
    halt env, status_code: 400, response: ({
      errcode: "SY_MALFORMED",
      error: "JSON was malformed: #{ex.message}",
      "retry_after_ms": 0
    }.to_json)
  end
end

get "/session/:name/queue/:song" do |env|
  name = env.params.url["name"]
  song = env.params.url["song"]
  song.to_json
end

get "/session/:name/player" do |env|
  name = env.params.url["name"]
  player.to_json
end

get "/session/:name/player/current" do |env|
  name = env.params.url["name"]
  song.to_json
end

put "/session/:name/player/current" do |env|
  name = env.params.url["name"]
  begin
    song = Song.from_json env.params.json.to_json
    song.to_json  
  rescue ex : JSON::ParseException
    halt env, status_code: 400, response: ({
      errcode: "SY_MALFORMED",
      error: "JSON was malformed: #{ex.message}",
      "retry_after_ms": 0
    }.to_json)
  end
end

get "/session/:name/player/play" do |env|
  name = env.params.url["name"]
  {playing: player.playing}.to_json
end

put "/session/:name/player/play" do |env|
  name = env.params.url["name"]
  if env.params.json["playing"].as(Bool)
    player.play
  else
    player.pause
  end
  {playing: player.playing}.to_json
end

post "/session/:name/player/next" do |env|
  name = env.params.url["name"]
  begin
    player.previous
    {success: "skipping to next song in queue"}.to_json
  rescue OutOfBounds
    halt env, status_code: 400, response: ({
      errcode: "SY_OUT_OF_BOUND",
      error: "There is no next song in the queue",
      "retry_after_ms": 0
    }.to_json)
  end
end

post "/session/:name/player/previous" do |env|
  name = env.params.url["name"]
  begin
    player.previous
    {success: "skipping to previous song in queue"}.to_json
  rescue OutOfBounds
    halt env, status_code: 400, response: ({
      errcode: "SY_OUT_OF_BOUND",
      error: "There is no previous song in the queue",
      "retry_after_ms": 0
    }.to_json)
  end
end

get "/session/:name/users" do |env|
  name = env.params.url["name"]
  users.to_json
end

post "/session/:name/users" do |env|
  name = env.params.url["name"]
  begin
    data = env.params.json
    data["host"] = false
    user = User.from_json data.to_json
    user.to_json  
  rescue ex : JSON::ParseException
    halt env, status_code: 400, response: ({
      errcode: "SY_MALFORMED",
      error: "JSON was malformed: #{ex.message}",
      "retry_after_ms": 0
    }.to_json)
  end
end

get "/session/:name/users/:user" do |env|
  name = env.params.url["name"]
  user = User.new env.params.url["user"]
  user.to_json
end

patch "/session/:name/users/:user" do |env|
  name = env.params.url["name"]
  user = User.new env.params.url["user"]
  user.name = env.params.json["name"].not_nil!.as(String)
  user.image = env.params.json["image"].not_nil!.as(String)
  user.url = env.params.json["url"].not_nil!.as(String)
  user.to_json
end