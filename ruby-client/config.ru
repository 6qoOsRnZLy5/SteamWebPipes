require 'faye/websocket'
require 'eventmachine'
require 'faraday'
require 'json'
require 'rack'

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
def steam_store_url(id)
  "https://store.steampowered.com/app/#{id}/"
end
def steampic_banner(id)
  "https://steamcdn-a.akamaihd.net/steam/apps/#{id}/header_292x136.jpg"
end
def steampic_capsule(id)
  "https://steamcdn-a.akamaihd.net/steam/apps/#{id}/capsule_231x87.jpg"
end

STEAMALLAPPLIST = "https://api.steampowered.com/ISteamApps/GetAppList/v2/"
response = Faraday.get STEAMALLAPPLIST
responsehash = JSON.parse(response.body)
responsejson = responsehash.to_h
responseapplist = responsejson["applist"]
responseapplistapps = responseapplist["apps"]



h = Hash.new
responseapplistapps.each_entry do |e|
  appid = e["appid"]
  name = e["name"]
  h["#{appid}"] = name
end

puts responseapplistapps.first.inspect
puts h.first.inspect
puts responseapplistapps.count
puts h.count
puts responseapplistapps.last.inspect
puts h.to_a.last.inspect

EM.run {
  ws = Faye::WebSocket::Client.new(ws, ['steam-pics'])
  puts "em started"

  ws.on :message do |event|
    m = JSON.parse(event.data)
    puts m.inspect
    if m["Type"]
      if m["Type"] == "Changelist"
        changeid = m["ChangeNumber"]
        if m["Apps"]
          if m["Apps"].any?
            id = m["Apps"].keys.first
            puts "change #{changeid} is for an app #{id}"
            if h["#{id}"]
              puts "-> id #{id} IS in hash"
              name = h["#{id}"]
              puts name
              
              message = "Game #{name} updated!"
              steam_store_link = steam_store_url(id)
              steam_store_item = { title: 'View in Steam Store', url: steam_store_link }
              changeset_link = sdb_changeurl(changeid)
              changeset_item =  { title: "View this changeset", url: changeset_link }
              thumbnail_link = steampic_capsule(id)
              thumbnail_item = { thumbnail: { url: thumbnail_link } }
              embedds = [thumbnail_item, steam_store_item, changeset_item]
              
              resp = conn.post do |req|
                req.body = { username: "plebbot", content: message, embeds: embedds }.to_json
              end
                     
            else
              puts "-> id #{id} NOT in hash"
            end
          end
        end
        if m["Packages"].any?
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

run Proc.new { |env| ['200', {'Content-Type' => 'text/html'}, ['get rack\'d']] }
