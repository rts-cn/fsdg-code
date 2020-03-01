function log(k, v)
	if not v then v = "[NIL]" end
	freeswitch.consoleLog("INFO", k .. ": " .. v .. "\n")
end

cid = session:getVariable("caller_id_number")
dest = session:getVariable("destination_number")

log("From Lua DP: cid:  ", cid)
log("From Lua DP: dest: ", dest)

-- Some Bussinuss logic here

ACTIONS =  {
	{"log", "INFO I'm From Lua Dialplan"},
	{"log", "INFO Hello FreeSWITCH, Playing MOH ..."},
	"answer",
	{"playback", "local_stream://moh"}
}
