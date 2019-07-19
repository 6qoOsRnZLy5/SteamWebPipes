require 'faye/websocket'
require 'eventmachine'
require 'faraday'
require 'json'

webhook = ENV['DISCORD_REMOTE']
ws = ENV['WS_ENDPOINT']

conn = Faraday.new(
         url: webhook,
         headers: {'Content-Type' => 'application/json'}
)

puts "wss is #{ws}"
puts "discord is #{webhook}"

EM.run {
  ws = Faye::WebSocket::Client.new(ws, ['steam-pics'])
  puts "em started"
         
  ws.on :open do |event|
    p [:open]
    ws.send('Hello, world!')
    resp = conn.post do |req|
       req.body = { username: "test", content: 'connected!!!' }.to_json
    end
    puts resp.status
    puts resp.body
    puts "----------"
  end

  ws.on :message do |event|
    p [:message, event.data]
    resp = conn.post do |req|
      req.body = { username: "test", content: event.data }.to_json
    end
    puts resp.status
    puts resp.body
    puts "----------"
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
