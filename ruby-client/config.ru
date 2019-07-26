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
webhookF = ENV['DISCORD_REMOTE_F']
connF = Faraday.new(
         url: webhookF,
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

selectionapps = ["252490", "258550", "700580"]
selectionpacks = []

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

stable_client_role = ENV["NOTIFY_STABLE_CLIENT_ROLE"]
staging_client_role = ENV["NOTIFY_STAGING_CLIENT_ROLE"]
stable_server_role = ENV["NOTIFY_STABLE_SERVER_ROLE"]
def create_embds(changeid, gameid)
  if h["#{gameid}"]
    name = h["#{id}"]
  else 
    name = gameid
  end
  if gameid == "252490"
    mention = "<@&#{stable_client_role}>\n"
    color = 16384000
  elsif gameid == "258550"
    mention = "<@&#{stable_server_role}>\n"
    color = 16435200
  elsif gameid == "700580"
    mention = "<@&#{staging_client_role}>\n"
    color = 2554368
  else
    mention = String.new
    color = 2580357
  end
  title = "Game #{name} updated!"
  steam_store_link = steam_store_url(gameid)
  changeset_link = sdb_changeurl(changeid)
  description = "#{mention}[View App in Steam Store](#{steam_store_link})\n[View Change on SteamDB](#{changeset_link})"
  thumbnail_link = steampic_capsule(id)
  thumbe = { url: thumbnail_link }
  embededes = { title: title, description: description, color: color, thumbnail: thumbe }
  embededs = [ embededes ]
  return { username: "plebbot", embeds: embededs }.to_json
end

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
            # todo: iterate if there are multiple
            id = m["Apps"].keys.first
            puts "change #{changeid} is for an app #{id}"
            if h["#{id}"]
	      mybody = create_embds(changeid, id)
              
              resp = conn.post do |req|
                req.body = mybody
              end
                     
            else
              puts "-> id #{id} NOT in hash"
            end
            if selectionapps.include?(id)
              puts "selectionapps includes this id"
              if h["#{id}"]
                mybody = create_embds(changeid, id)

                resp = connF.post do |req|
                  req.body = mybody
                end
              end
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


