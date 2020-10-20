require "kemal"
require "json"
require "uuid"
require "uuid/json"

class User
  getter socket : HTTP::WebSocket
  getter id : UUID

  def initialize(@socket, @id)
  end
end

class Message
  getter data : String
  getter type : String

  def initialize(json : JSON::Any)
    if json["type"]?
      @data = json.to_json.not_nil!
      @type = json["type"].as_s
    else
      raise KeyError.new %(missing key "type")
    end
  end

  def initialize(type, **values : String | Bool | Number)
    @type = type
    @data = JSON.build do |json|
      json.object do
        json.field "type", type
        values.each do |key, value|
          json.field key, value
        end
      end
    end
  end
end

def sendTo(socket : HTTP::WebSocket, message : Message)
  socket.send message.data
end

def sendToAll(users : Enumerable, author_id : UUID, message : Message)
  users.each do |user|
    unless user.id == author_id
      user.socket.send message.data
    end
  end
end

users = Hash(String, Set(User)).new



ws "/session/:name" do |socket, context|
  name = context.ws_route_lookup.params["name"]
  unless users.has_key?(name)
    users[name] = Set(User).new
  end
  session = users[name]
 
  uuid = UUID.random

  # Send welcome message to the client
  sendTo(socket, Message.new type: "connect", message: "Welcome to #{name}!")

  # Handle incoming message
  socket.on_message do |data|
    message = Message.new(JSON.parse(data).not_nil!) # TODO: exception handling

    case message.type
    when "login"
      
      session.add(User.new(socket, uuid))
      sendToAll(session, uuid, Message.new type: "updateUsers", id: uuid.to_json)
      sendTo(socket, Message.new type: "login", success: true)
    else
      sendTo(socket, Message.new type: "error", message: "Command not found: #{message.type}")
    end
  end

  # Executes when the client is disconnected. You can do the cleaning up here.
  socket.on_close do
    puts "Closing socket"
  end
end  