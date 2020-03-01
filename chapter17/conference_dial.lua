prompt="tone_stream://%(10000,0,350,440)"
error="error.wav"
result = ""

extn = session:playAndGetDigits(1, 4, 3, 5000, '#', prompt, error, "\\d+")

session:execute("log", "INFO extn=" .. extn)
arg = "3000 dial user/" .. extn
session:execute("log", "INFO arg=" .. arg)

api = freeswitch.API()

if not (extn == "") then
	result = api:execute("conference", arg)
end

session:execute("log", "INFO result=" .. result)
