#include <stdio.h>
#include <stdlib.h>
#include <esl.h>

int main(void)
{
	esl_handle_t handle = {{ 0 }};
	struct esl_event *event;
	struct esl_event_header header;

	esl_event_create_subclass(&event,  ESL_EVENT_CUSTOM, "SMS::SEND_MESSAGE");
	esl_event_add_header_string(event, ESL_STACK_BOTTOM, "to", "1000@192.168.0.7");
	esl_event_add_header_string(event, ESL_STACK_BOTTOM, "from", "seven@192.168.0");
	esl_event_add_header_string(event, ESL_STACK_BOTTOM, "sip_profile", "internal");
	esl_event_add_header_string(event, ESL_STACK_BOTTOM, "dest_proto", "sip");
	esl_event_add_header_string(event, ESL_STACK_BOTTOM, "type", "text/plain");
	esl_event_add_body(event, "Hello");

	esl_connect(&handle, "localhost", 8021, NULL, "ClueCon");
	esl_send_recv(&handle, "api version\n\n");
	if (handle.last_sr_event && handle.last_sr_event->body) {
		printf("%s\n", handle.last_sr_event->body);
		printf("sending event....\n");
		esl_sendevent(&handle, event);
		esl_event_destroy(&event);
	} else {
		printf("%s\n", handle.last_sr_reply);
	}


	esl_disconnect(&handle);
	return 0;
}
