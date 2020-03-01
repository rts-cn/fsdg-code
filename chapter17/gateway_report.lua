--[[
	Author: Seven du (seven .. at .. idapted.com)
	Licence: MIT
	WWW: http://www.idapted.com
	

  Listen to FreeSWITCH events and report to
	1) fire an event
	2) post to a http server
	3) write to db (not yet implemented)
	
  Report when:                                                           
	1) more than 1 continues failed calls
	2) a successful call flowed by failed calls

  Params:	
	Total-Failed-Calls: Count of faied calls from init of the lua script
	Continue-Failed-Calls: counts till a succeful call detected
	Last-Failed-Calls: count of failed calls from the last report
	Last-Failed-Calls[x]: count of the last Sample-Time minutes
	Sample-Time[x]: not a continuouse time. Say if it's value is 5, and we catch an event once a minute, that would be 5 minutes. But if we catch an event once a day, can be five days.            
	
  Usage: in FreeSWITCH console or fs_cli,
	luarun gw.lua <http_post | fire_event | db >
	luarun gw.lua db [odbc | mysql | sqlite3 | psql | ... ]
	luarun gw.lua debug
	luarun gw.lua stop
	
	in lua.conf.xml:
	<param name="startup-script" value="gateway_report.lua"/>
	
  A sample event:

<event>
  <headers>
    <Event-Name>CUSTOM</Event-Name>
    <Core-UUID>94a01890-3e62-4758-b1a5-f2cbe0d7b4b3</Core-UUID>
    <FreeSWITCH-Hostname>localhost</FreeSWITCH-Hostname>
    <FreeSWITCH-IPv4>192.168.1.27</FreeSWITCH-IPv4>
    <FreeSWITCH-IPv6>%3A%3A1</FreeSWITCH-IPv6>
    <Event-Date-Local>2009-08-12%2010%3A38%3A05</Event-Date-Local>
    <Event-Date-GMT>Wed,%2012%20Aug%202009%2002%3A38%3A05%20GMT</Event-Date-GMT>
    <Event-Date-Timestamp>1250044685793509</Event-Date-Timestamp>
    <Event-Calling-File>switch_cpp.cpp</Event-Calling-File>
    <Event-Calling-Function>Event</Event-Calling-Function>
    <Event-Calling-Line-Number>235</Event-Calling-Line-Number>
    <Event-Subclass>luagw%3A%3Areport</Event-Subclass>
    <Sip-Gateway-Name>officepbx</Sip-Gateway-Name>
    <Sip-Gateway-Total-Calls>6</Sip-Gateway-Total-Calls>
    <Sip-Gateway-Last-Calls>6</Sip-Gateway-Last-Calls>
    <Sip-Gateway-Total-Failed-Calls>6</Sip-Gateway-Total-Failed-Calls>
    <Sip-Gateway-Continue-Failed-Calls>0</Sip-Gateway-Continue-Failed-Calls>
    <Sip-Gateway-Last-Failed-Calls>0</Sip-Gateway-Last-Failed-Calls>
    <Sip-Gateway-Last-Failed-Calls1>6</Sip-Gateway-Last-Failed-Calls1>
    <Sip-Gateway-Last-Failed-Calls2>6</Sip-Gateway-Last-Failed-Calls2>
    <Sip-Gateway-Sample-Time1>5</Sip-Gateway-Sample-Time1>
    <Sip-Gateway-Sample-Time2>10</Sip-Gateway-Sample-Time2>
  </headers>
</event>

	A Chinese explaination is available at: 
http://www.dujinfang.com/past/2010/3/13/zai-freeswitchzhong-zhi-xing-chang-qi-yun-xing-de-qian-ru-shi-jiao-ben-luayu-yan-li-zi/
]]

script_name = argv[0]
report_type = argv[1] or "http_post"

debug = {} 

function debug.var(k, v)
	v = v or 'nil'
	freeswitch.consoleLog("notice", "==DebugVar== " .. k .. ": " .. v .. "\n")
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
	debug.info("Sent stop message to lua script[" .. argv[0] .. "]")
	return;
end

if argv[1] == "debug" then
	local event = freeswitch.Event("custom", "lua::debugscript");
	event:addHeader("Seven", "7777777");
	event:fire();
	debug.info("Sent debug message to lua script[" .. argv[0] .. "]")
	return;
end

if report_type == "http_post" then
	require 'socket'
	local host = "127.0.0.1"
	local port = 3003
	local path = '/test.xml'

	function http_post(params)
                                   
		-- print("sending " .. params) 
		-- params = "<?xml version='1.0' encoding='UTF-8'?>\n" .. params .. "\n"
		local http_header = "POST " .. path .. " HTTP/1.1\r\n"
			.. "User-Agent: FreeSWITCH-Lua\r\n"
			.. "Host: " .. host .. ":" .. port .. "\r\n"
			.. "Accept: */*\r\n"
			.. "Connection: close\r\n"
			.. "Content-Length: " .. #params .. "\r\n"
			.. "Content-Type: application/xml\r\n\r\n"
	--		.. "Content-Type: application/x-www-form-urlencoded\r\n\r\n" .. params
			.. params

		-- print(http_header)

		local conn = socket.connect(host, port)
		if (conn) then
			conn:send(http_header)
			conn:close()
			return true
		else
			debug.notice("Error posting to server: " .. host .. ":" .. port )
		end            
		return false
	
	end
end


if report_type == "db" then
    
	TABLE_NAME = "voip_outbound_gateways"
    
    local db_adapter = argv[2] or 'sqlite3'

	if (db_adapter ~= "sqlite3" ) then
		debug.info( "db_adapter " .. db_adapter .. "not implemented yet!")
		return
	end

	require 'luasql.sqlite3'
	env = assert(luasql.sqlite3())
	db_conn = assert(env:connect ("test.sqlite3", "root", "", "localhost"))

	-- local sql = "CREATE TABLE " .. TABLE_NAME .. [[
	-- 	(   id integer pramary_key,
	-- 		gateway_name varchar(255), 
	-- 		total_calls integer default 0,
	-- 		total_failed_calls integer default 0,
	-- 		continue_failed_calls integer default 0,
	-- 		last_failed_calls1 integer default 0,
	-- 		last_failed_calls2 integer default 0 ); ]]
	-- print(sql)
	-- conn:execute(sql)
end

--Main function starts here                                                                   
freeswitch.consoleLog("info", "-- Lua Script [" .. argv[0] .. "] Starting --\n");
                      
local all_events = 0
local processed_events = 0
local event_name
local event_subclass
local gateways = {}
local SAMPLE_TIME1 = 5
local SAMPLE_TIME2 = 10            
local mt = {__index = function() return 0 end}

function ensure_gateway(gateway)
	-- ensure values not nil and numeric value default to 0
	if gateways[gateway] then return end
	
	gateways[gateway] = {last_failed_calls1 = {}, last_failed_calls2 = {}}
	setmetatable(gateways[gateway], mt)
	setmetatable(gateways[gateway].last_failed_calls1, mt)
	setmetatable(gateways[gateway].last_failed_calls2, mt)
end	                                                      

function prepare_event(gateway)

	local count1 = 0;
	local count2 = 0;
	
	for k,v in ipairs(gateways[gateway].last_failed_calls1) do
		count1 = count1 + v
	end
	for k,v in ipairs(gateways[gateway].last_failed_calls2) do
		count2 = count2 + v
	end
	
	local event = freeswitch.Event("custom", "luagw::report");
	event:addHeader("Sip-Gateway-Name", gateway)
	event:addHeader("Sip-Gateway-Total-Calls", gateways[gateway].total_calls)
	event:addHeader("Sip-Gateway-Last-Calls", gateways[gateway].last_calls)
	event:addHeader("Sip-Gateway-Total-Failed-Calls", gateways[gateway].total_failed_calls)
	event:addHeader("Sip-Gateway-Continue-Failed-Calls", gateways[gateway].continue_failed_calls)
	event:addHeader("Sip-Gateway-Last-Failed-Calls", gateways[gateway].last_failed_calls)
	event:addHeader("Sip-Gateway-Last-Failed-Calls1", count1)
	event:addHeader("Sip-Gateway-Last-Failed-Calls2", count2)
	event:addHeader("Sip-Gateway-Sample-Time1", SAMPLE_TIME1)
	event:addHeader("Sip-Gateway-Sample-Time2", SAMPLE_TIME2)
	return event
	                 
end        

function reset_gateway_values(gateway)
	gateways[gateway].last_failed_calls = 0
	gateways[gateway].last_calls = 0
end

function do_fire_gateway_event(gateway)
	local event = prepare_event(gateway)
	event:fire();
	reset_gateway_values(gateway)
end

function do_http_post(gateway)
	local event = prepare_event(gateway)
	if (http_post(event:serialize("xml"))) then
		reset_gateway_values(gateway)
	end
end	

function do_db_update(gateway)
	local count1 = 0;
	local count2 = 0;

	for k,v in ipairs(gateways[gateway].last_failed_calls1) do
		count1 = count1 + v
	end
	for k,v in ipairs(gateways[gateway].last_failed_calls2) do
		count2 = count2 + v
	end

	local sql = "UPDATE " .. TABLE_NAME
		.. " SET total_calls = total_calls + " .. gateways[gateway].last_calls
		.. ",    total_failed_calls = total_failed_calls + " .. gateways[gateway].last_failed_calls
		.. ",    last_failed_calls1 = " .. count1
		.. ",    last_failed_calls2 = " .. count2
		.. ",    continue_failed_calls = " .. gateways[gateway].continue_failed_calls
		.. " WHERE gateway_name = '" .. gateway .. "'"
	print(sql)
	local result = db_conn:execute(sql)
	if result and result > 0 then
		reset_gateway_values(gateway)
	end
end

function do_gateway_report(gateway)
	if (report_type == "fire_event") then
		do_fire_gateway_event(gateway)
	elseif (report_type == "http_post") then
		do_http_post(gateway) 
	elseif (report_type == "db") then
		do_db_update(gateway)
	else
		debug.notice("report_type " .. report_type .. " not yet implemented!")
	end
end
                                              
local index1 = 0;
local index2 = 0;                           

con = freeswitch.EventConsumer("all");                                                                         
for e in (function() return con:pop(1) end) do
  -- freeswitch.consoleLog("info", "event\n" .. e:serialize("xml"));
  	all_events = all_events + 1;
	
	event_name = e:getHeader("Event-Name") or ""
	event_subclass = e:getHeader("Event-Subclass") or ""
	
	if (event_name == "CHANNEL_HANGUP") then
		processed_events = processed_events + 1;

		local gateway = e:getHeader("variable_sip_gateway_name")
		debug.var("gateway_name", gateway)
		
		if (gateway) then       

			ensure_gateway(gateway)

			local hangup_cause = e:getHeader("Hangup-Cause")
			-- debug.var("hangup-cause", hangup_cause)
			gateways[gateway].total_calls =  gateways[gateway].total_calls + 1
			gateways[gateway].last_calls =  gateways[gateway].last_calls + 1

			if (e:getHeader("Answer-State") ~= "answered" and hangup_cause ~= "USER_BUSY") then
			
				gateways[gateway].total_failed_calls =  gateways[gateway].total_failed_calls + 1
				gateways[gateway].last_failed_calls =  gateways[gateway].last_failed_calls + 1
				gateways[gateway].continue_failed_calls =  gateways[gateway].continue_failed_calls + 1
				                       
				-- drop count values into a loop queue
				curr_timestamp = math.floor(tonumber(e:getHeader("Event-Date-Timestamp")) / 60000000)
				
				if (curr_timestamp == last_timestamp1) then
					gateways[gateway].last_failed_calls1[index1] = gateways[gateway].last_failed_calls1[index1] + 1
				else                                
					last_timestamp1 = curr_timestamp
					index1 = index1 < SAMPLE_TIME1 and (index1 + 1) or 1
					gateways[gateway].last_failed_calls1[index1] = 1
				end

				if (curr_timestamp == last_timestamp2) then
					gateways[gateway].last_failed_calls2[index2] = gateways[gateway].last_failed_calls2[index2] + 1
				else                                
					last_timestamp2 = curr_timestamp
					index2 = index2 < SAMPLE_TIME2 and (index2 + 1) or 1
					gateways[gateway].last_failed_calls2[index2] = 1
				end
								
				if (gateways[gateway].continue_failed_calls > 1) then
					do_gateway_report(gateway)
				end
			end
		end
		
	elseif (event_name == "CHANNEL_ANSWER") then
		processed_events = processed_events + 1;
	
		local gateway = e:getHeader("variable_sip_gateway_name")
		debug.var("gateway_name", gateway)
		
		if (gateway) then             
			ensure_gateway(gateway)

			if (gateways[gateway].continue_failed_calls > 0)  then
				gateways[gateway].continue_failed_calls = 0
	  			do_gateway_report(gateway)
			end
		end
		
	end     
	                                                                                 
	if (event_name == "CUSTOM" and event_subclass == "lua::stopscript") then
		freeswitch.consoleLog("info", "--lua Script [" .. argv[0] .. "] got stop message, Exiting--\n")
		break
	end
	
	if (event_name == "CUSTOM" and event_subclass == "lua::debugscript") then
		local message = "--lua Script [" .. argv[0] .. "] got debug message, Reporting--\n"
		                   
		message = message .. "all_events: " .. all_events .. "\n"
			.. "processed_events: " .. processed_events .. "\n"
		for g, gv in pairs(gateways) do 
			message = message .. "gateway: " .. g .. "\n"
				.. "total_failed_calls: " .. gv.total_failed_calls .. "\n"
				.. "continue_failed_calls: " .. gv.continue_failed_calls .. "\n"
				.. "last_failed_calls: " .. gv.last_failed_calls .. "\n"
				.. "index1: " .. index1 .. "\n"
				.. "index2: " .. index2 .. "\n"
			
			for k,v in ipairs(gv.last_failed_calls1) do
				message = message .. "last_failed_calls1[" .. k .. "]: " .. v .. "\n"
			end
			for k,v in ipairs(gv.last_failed_calls2) do
				message = message .. "last_failed_calls2[" .. k .. "]: " .. v .. "\n"
			end

		end
		debug.info(message)
	end
	
end 

