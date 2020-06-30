require "kemal"
require "./classes"

ws "/session/:name" do |socket, context|
  name = context.ws_route_lookup.params["name"]

  # Send welcome message to the client
  socket.send "Hello to session #{name}"

  # Handle incoming message and echo back to the client
  socket.on_message do |message|
    socket.send "Echo back from server #{message}"
  end

  # Executes when the client is disconnected. You can do the cleaning up here.
  socket.on_close do
    puts "Closing socket"
  end
end  