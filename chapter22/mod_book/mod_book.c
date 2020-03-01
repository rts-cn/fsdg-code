/* Book Example: Dialplan/App/API  Author: Seven Du */

#include <switch.h>

SWITCH_MODULE_LOAD_FUNCTION(mod_book_load);
SWITCH_MODULE_DEFINITION(mod_book, mod_book_load, NULL, NULL);

SWITCH_STANDARD_DIALPLAN(book_dialplan_hunt)
{
	switch_caller_extension_t *extension = NULL;
	switch_channel_t *channel = switch_core_session_get_channel(session);

	if (!caller_profile) {
		caller_profile = switch_channel_get_caller_profile(channel);
	}

	switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session), SWITCH_LOG_INFO,
		"Processing %s <%s>->%s in context %s\n",
		caller_profile->caller_id_name, caller_profile->caller_id_number,
		caller_profile->destination_number, caller_profile->context);

	if ((extension = switch_caller_extension_new(session, "book", "book")) == 0) {
		abort();
	}

	switch_caller_extension_add_application(session, extension,
		"log", "INFO Hey, I'm in the book");

	switch_caller_extension_add_application(session, extension,
		"book", "FreeSWITCH - The Definitive Guide");

	return extension;
}

SWITCH_STANDARD_APP(book_function)
{
    const char *name;

    if (zstr(data)) {
        name = "No Name";
    } else {
        name = data;
    }

    switch_log_printf(SWITCH_CHANNEL_SESSION_LOG(session),
        SWITCH_LOG_INFO, "I'm a book, My name is: %s\n", name);
}

SWITCH_STANDARD_API(book_api_function)
{
    const char *name;

    if (zstr(cmd)) {
        name = "No Name";
    } else {
        name = cmd;
    }

	stream->write_function(stream, "I'm a book, My name is: %s\n", name);

	return SWITCH_STATUS_SUCCESS;
}

SWITCH_MODULE_LOAD_FUNCTION(mod_book_load)
{
	switch_dialplan_interface_t *dp_interface;
	switch_application_interface_t *app_interface;
	switch_api_interface_t *api_interface;

	*module_interface = switch_loadable_module_create_module_interface(pool, modname);

	SWITCH_ADD_DIALPLAN(dp_interface, "book", book_dialplan_hunt);

	SWITCH_ADD_APP(app_interface, "book", "book example", "book example",
                       book_function, "<name>", SAF_SUPPORT_NOMEDIA);

	SWITCH_ADD_API(api_interface, "book", "book example",
					   book_api_function, "[name]");

	return SWITCH_STATUS_SUCCESS;
}
