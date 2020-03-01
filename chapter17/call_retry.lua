retries = 0
bridge_hangup_cause = ""
gateways = {"gw1", "gw2", "gw3", "gw4"}
dest = argv[1]

function call_retry()

    freeswitch.consoleLog("notice", "Calling [" .. dest .. "] From Lua\n");
    retries = retries + 1
    if not session.ready() then
            return;
    end

    dial_string = "sofia/gateway/" .. gateways[retries] .. "/" .. dest;
    freeswitch.consoleLog("notice", "Dialing [" .. dial_string .. "]\n");

    session:execute("bridge", dial_string);
    bridge_hangup_cause = session:getVariable("bridge_hangup_cause") or session:getVariable("originate_disposition");
    if (retries < 4 and
        (bridge_hangup_cause == "NORMAL_TEMPORARY_FAILURE" or
        bridge_hangup_cause == "NO_ROUTE_DESTINATION" or
        bridge_hangup_cause == "CALL_REJECTED" or
        bridge_hangup_cause == "INVALID_GATEWAY") ) then

        freeswitch.consoleLog("notice",
            "On calling [" .. dest .. "] hangup. Cause: [" ..
            bridge_hangup_cause .. "]. Retry: " .. retries .. " \n");
        session:sleep(1000);
        call_retry();
    else
        freeswitch.consoleLog("notice", "Retry Exceed, Now hangup!\n");
    end
end

session:preAnswer();
session:setVariable("hangup_after_bridge", "true");
session:setVariable("continue_on_fail", "true");

call_retry();
