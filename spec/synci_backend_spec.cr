require "./spec_helper"
require "http/web_socket"

describe "SynciBackend" do
  # TODO: Write tests

  it "login" do
    room = "test"

    clientA = HTTP::WebSocket.new("localhost", "/session/#{room}", 3030)
    clientB = HTTP::WebSocket.new("localhost", "/session/#{room}", 3030)
    clientC = HTTP::WebSocket.new("localhost", "/session/#{room}", 3030)

    clients = [
      clientA,
      clientB,
      clientC
    ]

    clients.each do |client|
      client.send %({"type": "login"})
    end

    spawn do
      clientA.run
    end
    spawn do
      clientB.run
    end
    spawn do
      clientC.run
    end
  end
end
