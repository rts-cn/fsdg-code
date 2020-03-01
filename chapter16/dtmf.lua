function onInputCBF(s, type, obj, arg)
    if (type == "dtmf") then
        freeswitch.consoleLog("INFO",
          "Got DTMF: " .. obj.digit .. " Duration: " .. obj.duration .. "\\n")
          if (obj.digit == "3") then
              return 'break'
          end
      end
      return ''
  end

session:setInputCallback('onInputCBF', '');
session:streamFile("local_stream://moh");
