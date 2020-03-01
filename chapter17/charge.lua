-- Calling card charging demo. Author: Seven Du

error_prompt = "say:输入错误，请重新输入"
digits = ""
balance = 100
charge = 100

function do_charge(account, charge)
	balance = balance + charge
	return balance
end

function main_menu()
	if not session:ready() then return end

	digits = session:playAndGetDigits(1, 1, 3, 5000, "#",
        "say:茶询请按1，充值请按2", error_prompt, "^1|2$")
        -- "say:查询请按1，充值请按2", error_prompt, "^1|2$")

	session:execute("log", "INFO main_menu:" .. digits)

	if not (digits == "") then
		ask_account(digits)
	else
		goodbye()
	end
end

function ask_account(service_type)
	if not session:ready() then return end

	digits = session:playAndGetDigits(4, 5, 3, 5000, "#",
        "say:请输入您的账号，以井号结束", error_prompt, "^\\d{4}$")

	session:execute("log", "INFO account:" .. digits)

	if not (digits == "") then
		account = digits
		if (service_type == "1") then
			ask_account_password()
		else
			ask_card()
		end
	else
		goodbye()
	end
end

function ask_card()
	if not session:ready() then return end

	digits = session:playAndGetDigits(4, 5, 3, 5000, "#",
        "say:请输入您的充值卡卡号，以井号结束", error_prompt, "^\\d{4}$")

	session:execute("log", "INFO card:" .. digits)

	if not (digits == "") then
		card = digits
		check_account_card()
	else
		goodbye()
	end
end

function ask_account_password()
	if not session:ready() then return end

	digits = session:playAndGetDigits(4, 5, 3, 5000, "#",
        "say:请输入您的密码，以井号结束", error_prompt, "^\\d{4}$")

	session:execute("log", "INFO account p:" .. digits)

	if not (digits == "") then
		password = digits
		check_account_password()
	else
		goodbye()
	end
end

function check_account_password()
	if not session:ready() then return end

	if (account == "1111" and password == "1111") then
		balance = 100
		session:speak("您的余额是" .. balance .. "元")
		session:sleep(500)
		main_menu()
	else
		sesson:speak("输入有误，请重新输入")
		main_menu()
	end
end

function check_account_card()
	if not session:ready() then return end

	if (account == "1111" and card == "2222") then
		balance = 100
		charge = 100
		session:speak("您要充值" .. charge .. "元")
		digits = session:playAndGetDigits(1, 1, 3, 10000, "#",
        "say:确认请按1，返回请按2", error_prompt, "^[12]$")

		if digits == "1" then
			balance = do_charge(account, charge)
			session:speak("充值成功，充值金额" .. charge ..
				"元，余额为" .. balance .. "元")
			main_menu()
		else
			if digits == "2" then
				session:sleep(500)
				main_menu()
			else
				goodbye()
			end
		end
	else
		session:speak("输入有误，请重新输入")
		ask_account("2")
	end
end

function goodbye()
	if not session:ready() then return end

	session:speak("再见")
	session:hangup()
end

session:set_tts_params("tts_commandline", "Ting-Ting");
session:setVariable("tts_engine", "tts_commandline")
session:setVariable("tts_voice", "Ting-Ting")

session:answer()
session:speak("您好，欢迎使用空中充值服务")

main_menu()
