require 'faye/websocket'
require 'eventmachine'
require 'faraday'

webhook = ENV['DISCORD_REMOTE']
ws = ENV['WS_ENDPOINT']

conn = Faraday.new(
         url: webhook,
         headers: {'Content-Type' => 'application/json'}
)

EM.run {
  ws = Faye::WebSocket::Client.new(ws, ['steam-pics'])

  ws.on :open do |event|
    p [:open]
    ws.send('Hello, world!')
    resp = conn.post do |req|
       req.body = "{\"username\": \"test\", \"content\": '\"connected!!!\"}"
    end
    puts resp.status
    puts resp.body
    puts "----------"
  end

  ws.on :message do |event|
    p [:message, event.data]
    resp = conn.post do |req|
      req.body = "{\"username\": \"test\", \"content\": '\"#{event.data}\"}"
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
