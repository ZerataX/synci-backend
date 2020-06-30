require "kemal"
require "swagger"
require "swagger/http/server"

require "./api"

builder = Swagger::Builder.new( 
  title: "synci_backend",
  version: {{ `shards version #{__DIR__}`.chomp.stringify }},
  description: "Backend for Synci",
  license: Swagger::License.new("MIT", "https://opensource.org/licenses/MIT"),
  contact: Swagger::Contact.new("zeratax", "mail@zera.tax", "https://github.com/zeratax/synci-backend/issues")
)

builder.add(Swagger::Object.new("Song", "object", [
  Swagger::Property.new("id", "string", example: "spotify:track:2mlGPkAx4kwF8Df0GlScsC"),
  Swagger::Property.new("name", "string", example: "Buttercup"),
  Swagger::Property.new("artist", "string", example: "Jack Stauber"),
  Swagger::Property.new("image", "string", example: "https://i.scdn.co/image/ab67616d00001e02affdacd1466cdde505ab97ee"),
  Swagger::Property.new("length", "integer", example: 234000),
]))

builder.add(Swagger::Object.new("User", "object", [
  Swagger::Property.new("url", "string", example: "https://open.spotify.com/user/icrxkcxt7hg47exe6emo6g3r7"),
  Swagger::Property.new("name", "string", example: "Mojibake"),
  Swagger::Property.new("image", "string", example: "https://i.scdn.co/image/ab6775700000ee855fdae9b1acbbd7a3d09e4200"),
  Swagger::Property.new("host", "bool", example: false),
]))

builder.add(Swagger::Object.new("Users", "object", [
  Swagger::Property.new("users", "array"),
]))

builder.add(Swagger::Object.new("Queue", "object", [
  Swagger::Property.new("songs", "array"),
]))

builder.add(Swagger::Object.new("Session", "object", [
  Swagger::Property.new("name", "string", example: "DoubleWizardSky"),
  Swagger::Property.new("queue", "Queue"),
  Swagger::Property.new("users", "Users"),
]))

builder.add(Swagger::Object.new("Player", "object", [
  Swagger::Property.new("currentSong", "Song"),
  Swagger::Property.new("playing", "bool", example: false),
  Swagger::Property.new("timecode", "integer", example: "Jack Stauber"),
  Swagger::Property.new("image", "string", example: "https://i.scdn.co/image/ab67616d00001e02affdacd1466cdde505ab97ee"),
  Swagger::Property.new("length", "integer", example: 161376),
  Swagger::Property.new("queue", "array"),
]))

builder.add(Swagger::Object.new("Error", "object", [
  Swagger::Property.new("errcode", "string", description: "An error code.", example: "SY_UNKNOWN"),
  Swagger::Property.new("error", "string", description: "A human-readable error message"),
  Swagger::Property.new("retry_after_ms", "integer", description: "An unknown error occurred"),
]))


builder.add(Swagger::Controller.new("Session", "Session Resources", [
  Swagger::Action.new("get", "/session/{name}", description: "get info on a session by name", parameters: [Swagger::Parameter.new("name", "path")], responses: [
      Swagger::Response.new("200", "Success response", "Session"),
      Swagger::Response.new("404", "Session not found", "Error")
  ])
]))
builder.add(Swagger::Controller.new("Queue", "Queue Resources", [
  Swagger::Action.new("get", "/session/{name}/queue", description: "get the songs in the queue", parameters: [Swagger::Parameter.new("name", "path")], responses: [
      Swagger::Response.new("200", "Success response", "Queue"),
      Swagger::Response.new("404", "Session not found", "Error")
  ]),
  Swagger::Action.new("post", "/session/{name}/queue", description: "Add song to Queue", parameters: [Swagger::Parameter.new("name", "path")],
      request: Swagger::Request.new([
        Swagger::Property.new("id", "string", required: true, description: "song identifier"),
        Swagger::Property.new("name", "string", required: true, description: "name of the song"),
        Swagger::Property.new("length", "integer", default_value: 0, description: "length in milliseconds"),
        Swagger::Property.new("artist", "string", description: "song artist"),
        Swagger::Property.new("image", "string", description: "song image"),
      ], "Form data", "application/json"), responses: [
        Swagger::Response.new("200", "Success response", "Song"),
        Swagger::Response.new("400", "Malformed Request", "Error"),
        Swagger::Response.new("404", "Session not found", "Error")
      ]
  )
]))
builder.add(Swagger::Controller.new("Player", "Player Resources", [
  Swagger::Action.new("get", "/session/{name}/player", description: "get information about the current playback", parameters: [Swagger::Parameter.new("name", "path")],
    responses: [
      Swagger::Response.new("200", "Success response", "Player"),
      Swagger::Response.new("404", "Session not found", "Error")
  ])
]))
builder.add(Swagger::Controller.new("User", "User Resources", [
  Swagger::Action.new("get", "/session/{name}/users", description: "get information about the currently listening user", parameters: [Swagger::Parameter.new("name", "path")],
    responses: [
      Swagger::Response.new("200", "Success response", "Users"),
      Swagger::Response.new("404", "Session not found", "Error")
  ]),
  Swagger::Action.new("post", "/session/{name}/users", description: "join the session as a user", parameters: [Swagger::Parameter.new("name", "path")],
    request: Swagger::Request.new([
        Swagger::Property.new("name", "string", required: true, description: "name of the user"),
        Swagger::Property.new("url", "string", description: "url to user profile or homepage"),
        Swagger::Property.new("image", "string", description: "user avatar"),
      ], "Form data", "application/json"), responses: [
        Swagger::Response.new("200", "Success response", "User"),
        Swagger::Response.new("400", "Malformed request", "Error")
      ]
  ),
  Swagger::Action.new("get", "/session/{name}/users/{user}", description: "get information about a specific user", parameters: [
    Swagger::Parameter.new("name", "path"),
    Swagger::Parameter.new("user", "path")], responses: [
      Swagger::Response.new("200", "Success response", "User"),
      Swagger::Response.new("404", "User not found", "Error"),
      Swagger::Response.new("404", "Session not found", "Error")
  ]),
  Swagger::Action.new("patch", "/session/{name}/users/{users}", description: "update a user profile", parameters: [
    Swagger::Parameter.new("name", "path"),
    Swagger::Parameter.new("user", "path")], request:
    Swagger::Request.new([
        Swagger::Property.new("name", "string", required: true, description: "name of the user"),
        Swagger::Property.new("url", "string", description: "url to user profile or homepage"),
        Swagger::Property.new("image", "string", description: "user avatar"),
      ], "Form data", "application/json"), responses: [
        Swagger::Response.new("200", "Success response", "User"),
        Swagger::Response.new("400", "Malformed request", "Error"),
        Swagger::Response.new("401", "Unauthorized request", "Error"),
        Swagger::Response.new("404", "User not found", "Error"),
        Swagger::Response.new("404", "Session not found", "Error")
      ]
  ),
]))


builder.add(Swagger::Server.new("http://localhost:{port}/", "Alias Name", [
  Swagger::Server::Variable.new("port", "3030", ["3030", "3000"], "API port"),
]))

builder.add(Swagger::Server.new("http://0.0.0.0:{port}/", "IP Address", [
  Swagger::Server::Variable.new("port", "3030", ["3030", "3000"], "API port"),
]))


swagger_api_endpoint = "http://localhost:3030"
swagger_web_entry_path = "/swagger"
swagger_api_handler = Swagger::HTTP::APIHandler.new(builder.built, swagger_api_endpoint)
swagger_web_handler = Swagger::HTTP::WebHandler.new(swagger_web_entry_path, swagger_api_handler.api_url)

add_handler swagger_api_handler
add_handler swagger_web_handler

Kemal.run(3030)
