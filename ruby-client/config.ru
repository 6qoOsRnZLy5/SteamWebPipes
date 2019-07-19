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

def sdb_changeurl(id)
  "https://steamdb.info/changelist/#{id}/"
end
def sdb_appurl(id)
  "https://steamdb.info/app/#{id}/"
end
def sdb_packurl(id)
  "https://steamdb.info/sub/#{id}/history/"
end
def swa_appdetails(id)
  "https://store.steampowered.com/api/appdetails?appids=#{id}"
end
def swa_appnews(id)
  "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=#{id}"
end
def ssf_appnewsrss(id)
  "https://steamcommunity.com/games/#{id}/rss/"
end

STEAMALLAPPLIST = "https://api.steampowered.com/ISteamApps/GetAppList/v2/"
response = Faraday.get STEAMALLAPPLIST
applistjson = JSON.parse(response.body)
applist = applistjson[:applist][:apps]
h = Hash.new

applist.each_entry do |e|
  appid = e[:appid]
  name = e[:name]
  h[appid] = name
end


puts "wss is #{ws}"
puts "discord is #{webhook}"
EM.run {
  ws = Faye::WebSocket::Client.new(ws, ['steam-pics'])
  puts "em started"

  ws.on :message do |event|
    p [:message, event.data]
    resp = conn.post do |req|
      req.body = { username: "test", content: event.data }.to_json
    end
    puts "----- #{resp.body} -----"
    if m[:Type]
      if m[:Type] = "Changelist"
        puts m[:ChangeNumber] 
        if m[:Apps].any?
          puts "change is for an app"
          id = m[:Apps].keys.first
          if h.has_key(id)
            puts h[id]
          end
        end
        if m[:Packages].any?
          puts "change is for an package"
        end
      end
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
