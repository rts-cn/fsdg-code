#include <stdio.h>
#include <stdlib.h>
#include <esl.h>

#define ERROR_PROMPT "say:输入错误，请重新输入"
#define BALANCE 100
#define CHARGE  100
#define set_string(dest, str) strncpy(dest, str, sizeof(dest))
#define ENSURE_INPUT(input) if (!input) { \
	esl_execute(ch->handle, "speak", "再见", NULL); \
	/* sleep(1); */\
	esl_execute(ch->handle, "hangup", NULL, NULL); \
	return; \
}

typedef enum charge_menu_s {
	CHARGE_MENU_NONE,
	CHARGE_MENU_QUERY,
	CHARGE_MENU_CHARGE
} charge_menu_t;

typedef enum charge_state {
	CHARGE_WELCOME,
	CHARGE_MENU,
	CHARGE_WAIT_ACCOUNT,
	CHARGE_WAIT_ACCOUNT_PASSWORD,
	CHARGE_WAIT_CARD,
	CHARGE_WAIT_CONFIRM
} charge_state_t;

typedef struct charge_helper_s {
	esl_handle_t *handle;
	charge_state_t state;
	charge_menu_t menu;
	char account[20];
	char card[20];
	int balance;
} charge_helper_t;

char * get_digits(esl_event_t *event)
{
	char *digits = esl_event_get_header(event, "variable_digits");
	if (digits) esl_log(ESL_LOG_INFO, "digits: %s\n", digits);
	return digits;
}

int check_account_password(char *account, char *password)
{
	return (!strcmp(account, "1111")) && (!strcmp(password, "1111"));
}

int check_account_card(char *account, char *card)
{
	return (!strcmp(account, "1111")) && (!strcmp(card, "2222"));
}

int do_charge(int balance, int charge)
{
	return balance + charge;
}

static void event_callback(charge_helper_t *ch)
{
	char *application = NULL;
	esl_event_t *event = ch->handle->last_ievent;

	// esl_log(ESL_LOG_INFO, "event_id: %d\n", event->event_id);

	if (event->event_id != ESL_EVENT_CHANNEL_EXECUTE_COMPLETE) return;

	application = esl_event_get_header(event, "Application");
	esl_log(ESL_LOG_INFO, "State: %d Application: %s\n", ch->state, application);

	switch(ch->state) {
		case CHARGE_WELCOME:
			if (!strcmp(application, "speak")) {
select_menu:
				ch->state = CHARGE_MENU;
				esl_execute(ch->handle, "play_and_get_digits",
					"1 1 3 5000 # 'say:查询请按1，充值请按2' "
					ERROR_PROMPT " digits ^\\d$", NULL);
			}
			break;
		case CHARGE_MENU:
			if (!strcmp(application, "play_and_get_digits")) {
				char *menu = get_digits(event);

				ENSURE_INPUT(menu)

				if (!strcmp(menu, "1")) {
					ch->menu = CHARGE_MENU_QUERY;
				} else if (!strcmp(menu, "2")) {
					ch->menu = CHARGE_MENU_CHARGE;
				}

				ch->state = CHARGE_WAIT_ACCOUNT;
				esl_execute(ch->handle, "play_and_get_digits",
					"4 5 3 5000 # 'say:请输入您的账号，以井号结束' "
					ERROR_PROMPT " digits ^\\d{4}$", NULL);
			}
			break;
		case CHARGE_WAIT_ACCOUNT:
			if (!strcmp(application, "play_and_get_digits")) {
				char *account = get_digits(event);

				ENSURE_INPUT(account)

				set_string(ch->account, account);

				if (ch->menu == CHARGE_MENU_QUERY) {
					ch->state = CHARGE_WAIT_ACCOUNT_PASSWORD;
					esl_execute(ch->handle, "play_and_get_digits",
						"4 5 3 5000 # 'say:请输入您的密码，以井号结束' "
						ERROR_PROMPT " digits ^\\d{4}$", NULL);
				} else if (ch->menu == CHARGE_MENU_CHARGE) {
					ch->state = CHARGE_WAIT_CARD;
					esl_execute(ch->handle, "play_and_get_digits",
						"4 5 3 5000 # 'say:请输入您的充值卡卡号，以井号结束' "
						ERROR_PROMPT " digits ^\\d{4}$", NULL);
				} else {
					ch->state = CHARGE_WELCOME;
					esl_execute(ch->handle, "speak", "输入有误，请重新输入", NULL);
				}
			}
			break;
		case CHARGE_WAIT_ACCOUNT_PASSWORD:
			if (!strcmp(application, "play_and_get_digits")) {
				char *password = get_digits(event);

				ENSURE_INPUT(password)

				if (check_account_password(ch->account, password)) {
					char buffer[1024];
					sprintf(buffer, "您的余额是%d元", ch->balance);
					ch->state = CHARGE_WELCOME;
					esl_execute(ch->handle, "speak", buffer, NULL);
				} else {
					ch->state = CHARGE_WELCOME;
					esl_execute(ch->handle, "speak", "输入有误，请重新输入", NULL);
				}
			}
			break;
		case CHARGE_WAIT_CARD:
			if (!strcmp(application, "play_and_get_digits")) {
				char *card = get_digits(event);

				ENSURE_INPUT(card)

				if (check_account_card(ch->account, card)) {
					char buffer[1024];
					sprintf(buffer, "您要充值%d元", CHARGE);
					esl_execute(ch->handle, "speak", buffer, NULL);
					// sleep(2);
					ch->state = CHARGE_WAIT_CONFIRM;
					esl_execute(ch->handle, "play_and_get_digits",
						"1 1 3 5000 # 'say:确认请按1，返回请按2' "
						ERROR_PROMPT " digits ^\\d$", NULL);
				} else {
					ch->state = CHARGE_WELCOME;
					esl_execute(ch->handle, "speak", "输入有误，请重新输入", NULL);
				}
			}
			break;
		case CHARGE_WAIT_CONFIRM:
			if (!strcmp(application, "play_and_get_digits")) {
				char *confirm = get_digits(event);

				ENSURE_INPUT(confirm)

				if (!strcmp(confirm, "1")) {
					char buffer[1024];

					ch->balance = do_charge(ch->balance, CHARGE);
					sprintf(buffer, "充值成功，充值金额%d元，余额为%d元", CHARGE, ch->balance);
					ch->state = CHARGE_WELCOME;
					esl_execute(ch->handle, "speak", buffer, NULL);
				} else if (!strcmp(confirm, "2")) {
					ch->state = CHARGE_WELCOME;
					goto select_menu;
				}
			}
			break;
		default:
			break;
	}

}

static void charge_callback(esl_socket_t server_sock, esl_socket_t client_sock, struct sockaddr_in *addr, void *user_data)
{
	esl_handle_t handle = {{0}};
	esl_status_t status;
	charge_helper_t charge_helper = { 0 };

	charge_helper.handle = &handle;
	charge_helper.balance = BALANCE;
	charge_helper.state = CHARGE_WELCOME;

	esl_attach_handle(&handle, client_sock, addr);
	esl_log(ESL_LOG_INFO, "Connected! %d\n", handle.sock);
	esl_events(&handle, ESL_EVENT_TYPE_PLAIN, "CHANNEL_EXECUTE_COMPLETE");
	esl_filter(&handle, "Unique-ID", esl_event_get_header(handle.info_event, "Caller-Unique-ID"));
	esl_send_recv(&handle, "linger 5");
   	esl_log(ESL_LOG_INFO, "%s\n", handle.last_sr_reply);

	esl_execute(&handle, "answer", NULL, NULL);
	esl_execute(&handle, "set", "tts_engine=tts_commandline", NULL);
	esl_execute(&handle, "set", "tts_voice=Ting-Ting", NULL);
	esl_execute(&handle, "speak", "您好，欢迎使用空中充值服务", NULL);

	while((status = esl_recv(&handle)) == ESL_SUCCESS) {
		const char *type = esl_event_get_header(handle.last_event, "content-type");
		if (type && !strcasecmp(type, "text/event-plain")) {
			event_callback(&charge_helper);
		}
	}

	esl_log(ESL_LOG_INFO, "Disconnected! %d\n", handle.sock);
	esl_disconnect(&handle);
}

int main(void)
{
	esl_global_set_default_logger(ESL_LOG_LEVEL_INFO);
	esl_listen_threaded("localhost", 8040, charge_callback, NULL, 100000);

	return 0;
}

