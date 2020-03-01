function log(text)
	freeswitch.consoleLog("INFO", text);
end

function onInput(s, type, obj)

	log("Callback type:" .. type)
	if (type == "dtmf") then
		log("DTMF: " .. obj.digit .. "\n")
		return "break"
	end

	if (type == "event") then
		local event = obj:getHeader("Speech-Type")
		if (event == "begin-speaking") then
			log("\n" .. obj:serialize())
			return ""
		end

		if (event == "detected-speech") then
			session:execute("detect_speech", "pause")
			log("\n" .. obj:serialize())

			if (obj:getBody()) then
				session:execute("detect_speech", "pause")
				local speech_ouput = obj:getBody()
				results = getResults(obj:getBody())
				if(results.score ~= nil) then
					log("Heard: CONFIDENCE = " .. results.score .. "\n")
					log("Heard: " .. results.text)
					s:speak("我听到您说的是" .. results.text .. "\n")
				else
					session:speak("对不起，我听不见你说话")
				end
				session:sleep(100)
			end
			return "break"
		else
			session:speak("对不起，我听不见你说话")
			return "break"
		end
		return "break"
	end
	return "break"
end

results = {};
speech_detected = false;
speech_detected_dest = false;

session:sleep(1000);
session:answer();
session:setInputCallback("onInput");
session:sleep(200);
session:set_tts_params("tts_commandline", "Ting-Ting");
session:speak("请说出一个名字");
session:execute("detect_speech", "pocketsphinx zh zh");
session:streamFile("silence_stream://0");
