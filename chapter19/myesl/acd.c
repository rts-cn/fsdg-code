#include <stdio.h>
#include <stdlib.h>
#include <esl.h>

#define MAX_AGENTS 3
#define set_string(dest, str) strncpy(dest, str, sizeof(dest) - 1)

typedef enum agent_state_s {
	AGENT_IDLE,
	AGENT_BUSY,
	AGENT_FAIL
} agent_state_t;

typedef struct agent_s {
	char exten[10];
	char uuid[37];
	agent_state_t state;
} agent_t;

static agent_t AGENTS[MAX_AGENTS] = { { 0 } };
static esl_mutex_t *MUTEX;
static int last_agent_index = MAX_AGENTS - 1;

void init_agents()
{
	set_string(AGENTS[0].exten, "1000");
	set_string(AGENTS[1].exten, "1001");
	set_string(AGENTS[2].exten, "1002");
}

agent_t *find_available_agent()
{
	int last;
	agent_t *agent;

	esl_mutex_lock(MUTEX);
	last = last_agent_index;

	while (1) {
		if (last_agent_index >= MAX_AGENTS - 1) {
			last_agent_index = 0;
		} else {
			last_agent_index++;
		}

		agent = &AGENTS[last_agent_index];

		esl_log(ESL_LOG_INFO, "Comparing agent [%d:%s:%s]\n",
			last_agent_index, agent->exten, agent->state == AGENT_IDLE ? "IDLE" : "BUSY");

		if (agent->state == AGENT_IDLE) {
			agent->state = AGENT_BUSY;
			esl_mutex_unlock(MUTEX);
			return agent;
		}

		if (last_agent_index == last) break;
	}

	esl_mutex_unlock(MUTEX);
	return NULL;
}

void reset_agent(agent_t *agent)
{
	esl_mutex_lock(MUTEX);
	agent->state = AGENT_IDLE;
	*agent->uuid = '\0';
	esl_mutex_unlock(MUTEX);
}

static void acd_callback(esl_socket_t server_sock, esl_socket_t client_sock, struct sockaddr_in *addr, void *user_data)
{
	esl_handle_t handle = {{0}};
	esl_status_t status = ESL_SUCCESS;
	agent_t *agent = NULL;
	const char *cid_name, *cid_number;

	esl_attach_handle(&handle, client_sock, addr);

	cid_name = esl_event_get_header(handle.info_event, "Caller-Caller-ID-Name");
	cid_number = esl_event_get_header(handle.info_event, "Caller-Caller-ID-Number");
	esl_log(ESL_LOG_INFO, "New Call From \"%s\" <%s>\n", cid_name, cid_number);

	esl_send_recv(&handle, "myevents");
	esl_log(ESL_LOG_INFO, "%s\n", handle.last_sr_reply);
	esl_send_recv(&handle, "linger 5");
	esl_log(ESL_LOG_INFO, "%s\n", handle.last_sr_reply);

	esl_execute(&handle, "answer", NULL, NULL);
	esl_execute(&handle, "set", "tts_engine=tts_commandline", NULL);
	esl_execute(&handle, "set", "tts_voice=Ting-Ting", NULL);
	esl_execute(&handle, "set", "continue_on_fail=true", NULL);
	esl_execute(&handle, "set", "hangup_after_bridge=true", NULL);
	esl_execute(&handle, "speak", "您好，欢迎致电，电话接通中，请稍侯", NULL);
	sleep(5);
	esl_execute(&handle, "playback", "local_stream://moh", NULL);

	while(status == ESL_SUCCESS || status == ESL_BREAK) {
		const char *type;
		const char *application;

		status = esl_recv_timed(&handle, 1000);

		if (status == ESL_BREAK) {
			if (!agent) {
				agent = find_available_agent();

				if (agent) {
					char dial_string[1024];
					sprintf(dial_string, "user/%s", agent->exten);
					esl_execute(&handle, "break", NULL, NULL);
					esl_execute(&handle, "bridge", dial_string, NULL);
					esl_log(ESL_LOG_INFO, "Calling: %s\n", dial_string);
				}
			}
			continue;
		}

		type = esl_event_get_header(handle.last_event, "content-type");

		if (type && !strcasecmp(type, "text/event-plain")) {
			// esl_log(ESL_LOG_INFO, "Event: %s\n", esl_event_get_header(handle.last_ievent, "Event-Name"));

			switch (handle.last_ievent->event_id) {
				case ESL_EVENT_CHANNEL_BRIDGE:
					set_string(agent->uuid, esl_event_get_header(handle.last_ievent, "Other-Leg-Unique-ID"));
					esl_log(ESL_LOG_INFO, "bridged to %s\n", agent->exten);
					break;
				case ESL_EVENT_CHANNEL_HANGUP_COMPLETE:
					esl_log(ESL_LOG_INFO, "Caller \"%s\" <%s> Hangup \n", cid_name, cid_number);
					if (agent) reset_agent(agent);
					goto end;
				case ESL_EVENT_CHANNEL_EXECUTE_COMPLETE:
					application = esl_event_get_header(handle.last_ievent, "Application");
					if (!strcmp(application, "bridge")) {
						const char *disposition = esl_event_get_header(handle.last_ievent, "variable_originate_disposition");
						esl_log(ESL_LOG_INFO, "Disposition: %s\n", disposition);
						if (!strcmp(disposition, "CALL_REJECTED") ||
							!strcmp(disposition, "USER_BUSY")) {
							reset_agent(agent);
							agent = NULL;
						}
					}
					break;
				default:
					break;
			}

		}
	}

end:

	esl_log(ESL_LOG_INFO, "Disconnected! status = %d\n", status);
	esl_disconnect(&handle);
}

int main(void)
{
	esl_mutex_create(&MUTEX);
	init_agents();

	esl_global_set_default_logger(ESL_LOG_LEVEL_INFO);
	esl_log(ESL_LOG_INFO, "ACD Server listening at localhost:8040 ...\n");
	esl_listen_threaded("localhost", 8040, acd_callback, NULL, 100000);

	esl_mutex_destroy(&MUTEX);

	return 0;
}

