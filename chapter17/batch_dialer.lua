--[[
	Author: Seven du (seven .. at .. idapted.com)
	Licence: MIT
	WWW: http://www.idapted.com
	
	FreeSWITCH batch dialer
	Dial numbers in <number_file_name> and playback a sound,
	no more than <max_calls> calls in concurrent.
	
	Usage: luarun batch_dialer.lua <max_calls>
	       luarun batch_dialer.lua stop          
	
	Disclamer: Note, this is just an example and it might have bugs
	
]]

dialer_value = argv[0] or "batch_dialer.lua"
-- prefix = "{ignore_early_media=true}sofia/gateway/cnc/"
prefix = "{ignore_early_media=true,dialer_var=" .. dialer_value .. "}user/"
number_file_name = "/usr/local/freeswitch/scripts/number.txt"
file_to_play = "/usr/local/freeswitch/sounds/custom/8000/sound.wav"
log_file_name = "/usr/local/freeswitch/log/dialer_log.txt"

con = freeswitch.EventConsumer("all");      

freeswitch.consoleLog("info", "==== Lua Script [" .. argv[0] .. "] Starting =====\n");
                        
local all_events = 0;
local event_name
local event_subclass
               
debug = {} 

function debug.var(k, v)
	v = v or 'nil'
	freeswitch.consoleLog("notice", "====DebugVar=== " .. k .. ": " .. v .. "\n")
end

function debug.info(s)
	freeswitch.consoleLog("info", s .. "\n")
end

function debug.notice(s)
	freeswitch.consoleLog("notice", s .. "\n")
end

if argv[1] == "stop" then 
        local event = freeswitch.Event("custom", "lua::stopscript");
        event:addHeader("Seven", "7777777");
        event:fire();
        debug.info("stop message sent to lua script[" .. argv[0] .. "]")
        return;
end                                                                                                                 

number_file = io.open(number_file_name, "r")
log_file = io.open(log_file_name, "a+")
max_calls = tonumber(argv[1] or 10)
current_calls = 0
                          
debug.info("Max calls: " .. max_calls)

function log(s)
	log_file:write(os.date("%H:%M:%S ") .. s .. "\n") 
	log_file:flush() 
end
       
api = freeswitch.API();
 
function new_call()
	line = number_file:read("*line")
	if line == "" or line == nil then return 0 end
	
	api:execute("bgapi", "originate " .. prefix .. line .. " &echo()")
	return 1;

end
                              
function init_call()
          
	while current_calls < max_calls do
		if (new_call() == 0) then return 0 end
		current_calls = current_calls + 1
	end
	return current_calls
end

init_call()                                     

for e in (function() return con:pop(1) end) do

  -- freeswitch.consoleLog("info", "event\n" .. e:serialize("xml"));
  	all_events = all_events + 1;
	freeswitch.consoleLog("info", "all_events: " .. all_events .. "\n")
	
	event_name = e:getHeader("Event-Name") or ""
		debug.info(event_name)
	event_subclass = e:getHeader("Event-Subclass") or ""
	
	if (event_name == "CHANNEL_HANGUP") then
  -- freeswitch.consoleLog("info", "event\n" .. e:serialize("xml"));

		local dialer_var = e:getHeader("variable_dialer_var")
		if (dialer_var == dialer_value) then
			dest = e:getHeader("Caller-Destination-Number")
			cause = e:getHeader("Hangup-Cause")
			log(dest .. " " .. cause)
			if (new_call() == 0) then break end
		end          
		
	elseif (event_name == "CHANNEL_ORIGINATE") then
		local dialer_var = e:getHeader("variable_dialer_var")		
	end     
	                                                                                 
	if (event_name == "CUSTOM" and event_subclass == "lua::stopscript") then
	  freeswitch.consoleLog("info", "-----lua Script [" .. argv[0] .. "]---Exiting------\n")
	  break
	end

	
end 

