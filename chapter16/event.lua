function log(k, v)
    if not v then v = "[NIL]" end
    freeswitch.consoleLog("INFO", k .. ": " .. v .. "\n")
end

event = freeswitch.Event("CUSTOM", "freeswitch:book")
event:addHeader("Author", "Seven Du")
event:addHeader("Content-Type", "text/plain")
event:addBody("FreeSWITCH: The Definitive Guide")

type = event:getType()

author = event:getHeader("Author")

text=event:serialize()
json=event:serialize("json")
xml=event:serialize("XML")

log("type", type)
log("author", author)
log("text", text)
log("json", json)
log("xml", xml)

event:fire()
log("MSG", "Event Fired")
