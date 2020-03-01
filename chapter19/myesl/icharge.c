#include <stdio.h>
#include <stdlib.h>
#include <esl.h>

#define ERROR_PROMPT "say:输入错误，请重新输入"

int check_account_password(const char *account, const char *password)
{
    return (!strcmp(account, "1111")) && (!strcmp(password, "1111"));
}

void process_event(esl_handle_t *handle, esl_event_t *event)
{
    const char *uuid;
    switch (event->event_id) {
        case ESL_EVENT_CHANNEL_PARK:
        {
            const char *service;

            service = esl_event_get_header(event, "variable_service");
            esl_log(ESL_LOG_INFO, "Service: %s\n", service);

            if (!service || (service && strcmp(service, "icharge"))) break;

            uuid = esl_event_get_header(event, "Caller-Unique-ID");
            esl_log(ESL_LOG_INFO, "New Call %s\n", uuid);

            esl_execute(handle, "answer", NULL, uuid);
            esl_execute(handle, "set", "tts_engine=tts_commandline", uuid);
            esl_execute(handle, "set", "tts_voice=Ting-Ting", uuid);
            esl_execute(handle, "speak", "您好，欢迎使用空中充值服务", uuid);

again:
            esl_execute(handle, "set", "charge_state=WAIT_ACCOUNT", uuid);

            esl_execute(handle, "play_and_get_digits",
                "4 5 3 5000 # 'say:请输入您的账号，以井号结束' "
                ERROR_PROMPT " charge_account ^\\d{4}$", uuid);

            esl_execute(handle, "set", "charge_state=WAIT_PASSWORD", uuid);

            esl_execute(handle, "play_and_get_digits",
                "4 5 3 5000 # 'say:请输入您的密码，以井号结束' "
                ERROR_PROMPT " charge_password ^\\d{4}$", uuid);

            break;
        }
        case ESL_EVENT_CHANNEL_EXECUTE_COMPLETE:
        {
            const char *application;
            const char *charge_state;

            uuid = esl_event_get_header(event, "Caller-Unique-ID");
            application = esl_event_get_header(event, "Application");
            charge_state = esl_event_get_header(event, "variable_charge_state");

            if (!strcmp(application, "play_and_get_digits") &&
                !strcmp(charge_state, "WAIT_PASSWORD")) {

                const char *account = esl_event_get_header(event, "variable_charge_account");
                const char *password = esl_event_get_header(event, "variable_charge_password");

                if (account && password && check_account_password(account, password)) {
                    esl_log(ESL_LOG_INFO, "Account: %s Balance: 100\n", account);
                    esl_execute(handle, "speak", "您的余额是100元", uuid);
                    esl_execute(handle, "speak", "再见", uuid);
                    esl_execute(handle, "hangup", NULL, uuid);
                } else {
                    esl_execute(handle, "speak", "账号密码错误", uuid);
                    goto again;
                }
            }
            break;
        }
        case ESL_EVENT_CHANNEL_HANGUP_COMPLETE:
            uuid = esl_event_get_header(event, "Caller-Unique-ID");
            esl_log(ESL_LOG_INFO, "Hangup %s\n", uuid);
            break;
        default:
            break;
    }
}

int main(void)
{
	esl_handle_t handle = {{0}};
	esl_status_t status;
    const char *uuid;

    esl_global_set_default_logger(ESL_LOG_LEVEL_INFO);

    status = esl_connect(&handle, "127.0.0.1", 8022, NULL, "ClueCon");

    if (status != ESL_SUCCESS) {
        esl_log(ESL_LOG_INFO, "Connect Error: %d\n", status);
        exit(1);
    }

    esl_log(ESL_LOG_INFO, "Connected to FreeSWITCH\n");
    esl_events(&handle, ESL_EVENT_TYPE_PLAIN,
        "CHANNEL_PARK CHANNEL_EXECUTE_COMPLETE CHANNEL_HANGUP_COMPLETE");
    esl_log(ESL_LOG_INFO, "%s\n", handle.last_sr_reply);

    handle.event_lock = 1;
    while((status = esl_recv_event(&handle, 1, NULL)) == ESL_SUCCESS) {
        if (handle.last_ievent) {
            process_event(&handle, handle.last_ievent);
        }
	}

end:

	esl_disconnect(&handle);

	return 0;
}
