-- A resident script to run on a Clipsal 5500SHAC to push MQTT events to Cbus.

-- Tested with 5500SHAC firmware v1.6

-- Install this script as a resident script with a sleep interval of 5 seconds

mqtt_broker = 'xxx.xxx.xxx.xxx'
mqtt_username = 'xxxxxxxxxxxxxx'
mqtt_password = 'xxxxxxxxxxxxxxxxxxxxxxxxxxx'

mqtt_read_topic = 'cbus/read/'
mqtt_write_topic = 'cbus/write/#';

-- load mqtt module
mqtt = require("mosquitto")

-- create new mqtt client
client = mqtt.new()

--log("created MQTT client", client)

client.ON_CONNECT = function()
--  log("MQTT connected - receive")
  local mid = client:subscribe(mqtt_write_topic, 2)
end

client.ON_MESSAGE = function(mid, topic, payload)

 -- log(topic, payload)
  
  parts = string.split(topic, "/")

  if not parts[6] then
    
--    log('MQTT error', 'Invalid message format')
    
  elseif parts[6] == "getall" then
    
    datatable = grp.all()
    for key,value in pairs(datatable) do
      dataparts = string.split(value.address, "/")
		  network = tonumber(dataparts[1])
		  app = tonumber(dataparts[2])
      group = tonumber(dataparts[3])
      if app == tonumber(parts[4]) and group ~= 0 then
		    level = tonumber(value.data)
    		state = (level ~= 0) and "ON" or "OFF"
--        log(parts[3], app, group, state, level)
        client:publish(mqtt_read_topic .. parts[3] .. "/" .. app .. "/" .. group .. "/state", state, 1, true)
    		client:publish(mqtt_read_topic .. parts[3] .. "/" .. app .. "/" .. group .. "/level", level, 1, true)
  		end	
  	end
--    log('Done')
  elseif parts[6] == "switch" then
    
    if payload == "ON" then
			SetCBusLevel(0, parts[4], parts[5], 255, 0)
    elseif payload == "OFF" then
      SetCBusLevel(0, parts[4], parts[5], 0, 0)
    end
    
  elseif parts[6] == "measurement" then
 --   log(topic, payload)
    SetCBusMeasurement(0, parts[4], parts[5], (payload), 0)
  
  elseif parts[6] == "shedac_temp" then
--    log("user value")
--    log(0, parts[6], payload, 0)
    SetUserParam(0, parts[6], payload)
    
  elseif parts[6] == "ramp" then

    if payload == "ON" then
			SetCBusLevel(0, parts[4], parts[5], 255)
    elseif payload == "OFF" then
      SetCBusLevel(0, parts[4], parts[5], 0)
    else
      ramp = string.split(payload, ",")
      num = math.floor(ramp[1] + 0.5)
      if num and num < 256 then
        if ramp[2] ~= nil and tonumber(ramp[2]) > 1 then
	        SetCBusLevel(0, parts[4], parts[5], num, ramp[2])
        else
	        SetCBusLevel(0, parts[4], parts[5], num, 0)
        end
      end
    end    
  end
end

client:login_set(mqtt_username, mqtt_password)
client:connect(mqtt_broker)
client:loop_forever()
