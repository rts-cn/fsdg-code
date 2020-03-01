--[[
	Author: Seven du (seven .. at .. idapted.com)
	Licence: MIT
	WWW: http://www.idapted.com
	
	FreeSWITCH dialer
	Dial numbers in <number_file_name> and playback a sound once a time 
	
	Usage: luarun dialer.lua
	
	See also:
	http://www.dujinfang.com/past/2010/3/13/yi-ge-zai-freeswitchzhong-wai-hu-de-luajiao-ben/
]]

prefix = "{ignore_early_media=true}sofia/gateway/cnc/"
prefix = "{ignore_early_media=true}user/"
number_file_name = "/usr/local/freeswitch/scripts/number.txt"
file_to_play = "/usr/local/freeswitch/sounds/custom/8000/sound.wav"
log_file_name = "/usr/local/freeswitch/log/dialer_log.txt"


function debug(s)
	freeswitch.consoleLog("notice", s .. "\n")
end

function call_number(number)
	dial_string = prefix .. tostring(number);
	
	debug("calling " .. dial_string);
	session = freeswitch.Session(dial_string);

	if session:ready() then
		session:sleep(1000)
		session:streamFile(file_to_play)
		session:hangup()
	end
	-- waiting for hangup               
	while session:ready() do
		debug("waiting for hangup " .. number)
		session:sleep(1000)
	end
    
	return session:hangupCause()
end
	
	
number_file = io.open(number_file_name, "r")
log_file = io.open(log_file_name, "a+")

while true do

	line = number_file:read("*line")
	if line == "" or line == nil then break end

	hangup_cause = call_number(line)
	log_file:write(os.date("%H:%M:%S ") .. line .. " " .. hangup_cause .. "\n")
end

