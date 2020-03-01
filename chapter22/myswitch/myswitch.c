/* MySwitch using libfreeswitch */

#include <switch.h>

int main(int argc, char** argv)
{
	switch_core_flag_t flags = SCF_USE_SQL;
	switch_bool_t console = SWITCH_TRUE;
	const char *err = NULL;

    printf("Hello, MySWITCH is running ...\n");

	switch_core_set_globals();
	switch_core_init_and_modload(flags, console, &err);
	switch_core_runtime_loop(!console);
	return 0;
}
