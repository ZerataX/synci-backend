require "kemal"
require "json"
require "uuid"

class User
  getter socket : HTTP::WebSocket
  getter id : UUID

  def initialize(@socket, @id)
  end

  def to_s
    id.to_s
  end
end

class Message
  getter data : JSON::Any
  getter type : String

  def initialize(json : JSON::Any)
    if json["type"]?
      @data = json
      @type = json["type"].as_s
    else
      raise KeyError.new %(missing key "type")
    end
  end

  def initialize(type, **values : String | Bool | Number | Enumerable)
    @type = type
    string = JSON.build do |json|
      json.object do
        json.field "type", type
        values.each do |key, value|
          if value.is_a? Enumerable
            json.field key, do
              json.array do
                value.each do |element|
                  if element.is_a? Number
                    json.number element
                  else
                    json.string element
                  end
                end
              end
            end
          else
            json.field key, value
          end
        end
      end
    end
    @data = JSON.parse(string)
  end

  def to_s()
    @data.to_json
  end

  def ==(other : Message)
    return @data == other.data && @type == other.type
  end
end



sessions = Hash(String, Set(User)).new
hosts = Hash(String, User).new



def send_to(socket : HTTP::WebSocket, message : Message)
  socket.send message.to_s
end

def send_to_all(users : Enumerable, author_id : UUID, message : Message)
  users.each do |user|
    unless user.id == author_id
      user.socket.send message.to_s
    end
  end
end

def get_user_by_id(id : String, session : Set(User))
  session.find { |user| user.id == id }
end


ws "/session/:name" do |socket, context|
  name = context.ws_route_lookup.params["name"]
  uuid = UUID.random
  user = User.new(socket, uuid)

  unless sessions.has_key? name
    sessions[name] = Set(User).new
    hosts[name] = user
  end
  session = sessions[name]
  host = hosts[name]

  # Send welcome message to the client
  session.add(user)
  send_to(socket, Message.new type: "login", success: true, id: uuid.to_s)
  send_to_all(session, uuid, Message.new type: "add_user", id: uuid.to_s)

  # Handle incoming message
  socket.on_message do |data|
    begin
      message = Message.new(JSON.parse(data).not_nil!)

      case message.type
      when "show_users"
        send_to(socket, Message.new type: "current_users", users: session)
      when "current_host"
        send_to(socket, Message.new type: "current_host", host: host.not_nil!.id.to_s)
      when "kick"
        if user == host
          send_to_all(session, uuid, Message.new type: "remove_user", id: message.data["id"].to_s)
        else
          send_to(socket, Message.new type: "error", message: "You're not host of this session!")
        end
      when "change_host"
        if user == host
          new_host = get_user_by_id(message.data["id"].to_s, session)
          if new_host.nil?
            send_to(socket, Message.new type: "error", message: %(no user with id "#{message.data["id"].to_s}" found))
          else
            hosts[name] = get_user_by_id(message.data["id"].to_s, session).not_nil!
            send_to_all(session, uuid, Message.new type: "new_host", id: message.data["id"].to_s)
          end
        else
          send_to(socket, Message.new type: "error", message: "You're not host of this session!")
        end
      when "turn_credentials"
      when "relay_ICE_candidate"
      else
        send_to(socket, Message.new type: "error", message: "Command not found: #{message.type}")
      end
    rescue ex
      send_to(socket, Message.new type: "error", message: ex.message)
    end
  end

  # Executes when the client is disconnected. You can do the cleaning up here.
  socket.on_close do
    session.delete(user)
    send_to_all(session, uuid, Message.new type: "remove_user", id: uuid.to_s)
    # if host leaves, remove session if nobody left, or use first in line as new host
    if user == host
      if session.empty?
        sessions.delete(name)
      else
        hosts[name] = session.first
        host = hosts[name]
        send_to_all(session, uuid, Message.new type: "new_host", id: message.data["id"].to_s)
      end
    end
    
  end
end  