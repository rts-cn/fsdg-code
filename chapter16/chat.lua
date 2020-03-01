area_code = "010"
to_host = "192.168.0.2"

function log(k, v)
	if not v then v = "[NIL]" end
	freeswitch.consoleLog("INFO", k .. ": " .. v .. "\n")
end

log("Message", message:serialize())

to_user = message:getHeader("to")
message:delHeader("to")
message:addHeader("to", "internal/sip:" .. area_code .. to_user .. "@" .. to_host)

message:delHeader("to_host")
message:addHeader("to_host", to_host)

log("New Message", message:serialize())

message:chat_execute("send")
