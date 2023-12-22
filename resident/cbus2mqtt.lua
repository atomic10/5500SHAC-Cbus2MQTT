-- A resident script to run on a Clipsal 5500SHAC to push Cbus events to MQTT

-- Tested with 5500SHAC firmware v1.6

-- Install this script as a resident script with a sleep interval of 5 seconds


mqtt_broker = 'xxx.xxx.xxx.xxx'
mqtt_username = 'xxxxxxxxxxxxx'
mqtt_password = 'xxxxxxxxxxxxxxxxxxxxxxx'


mqtt_read_topic = 'cbus/read/'

-- load mqtt module
mqtt = require("mosquitto")

-- create new mqtt client
client = mqtt.new()

--log("created MQTT client", client)

-- C-Bus events to MQTT local listener
server = require('socket').udp()
server:settimeout(1)
server:setsockname('127.0.0.1', xxxx)

client.ON_CONNECT = function()
--  log("MQTT connected - send")
end

client:login_set(mqtt_username, mqtt_password)
client:connect(mqtt_broker)
client:loop_start()

while true do
	cmd = server:receive()
  --log(cmd)
	if cmd then
    parts = string.split(cmd, "/")
    -- check application - if lighting / 56
    if parts[2] == "56" then
    network = 254
    app = tonumber(parts[2])
    group = tonumber(parts[3])
    level = tonumber(parts[4])
  	state = (level ~= 0) and "ON" or "OFF"
    client:publish(mqtt_read_topic .. network .. "/" .. app .. "/" .. group .. "/state", state, 1, true)
    client:publish(mqtt_read_topic .. network .. "/" .. app .. "/" .. group .. "/level", level, 1, true)
      
    -- if application is measurement / 228
    elseif parts[2] == "228" then
      network = 254
      app = tonumber(parts[2])
      group = tonumber(parts[3])
      subgroup = tonumber(parts[4])
      status = tonumber(parts[5])
      client:publish(mqtt_read_topic .. network .. "/" .. app .. "/" .. group .. "/" .. subgroup .. "/status", status, 1, true)
  
      -- if application is Trigger 
    elseif parts[2] == "202" then
      log("trigger", cmd)
      network = 254
      app = tonumber(parts[2])
      group = tonumber(parts[3])
      status = tonumber(parts[4])
      client:publish(mqtt_read_topic .. network .. "/" .. app .. "/" .. group .. "/status", status, 1, true)     
    end
  end
end
