local x = 1

function onInput(s, type, obj, arg)
	if (type == "dtmf") then
		freeswitch.consoleLog("INFO", "DTMF: " .. obj.digit .. " Duration: " .. obj.duration .. "\n")
	if (obj.digit == "*") then
		x = x - 1
		if (x < 0) then x = 0 end
		n = x
	elseif (obj.digit == "#") then
		x = x + 1
		n = x
	else
		n = obj.digit
	end

	s:execute("system", "banner -w 40 " .. n)
	s:speak(n)
  end

  return ''
end

session:set_tts_params("tts_commandline", "Ting-Ting")
session:answer()
session:speak("冰冰你好，请按一个数字")
session:setInputCallback('onInput', '')
session:streamFile("local_stream://moh")
