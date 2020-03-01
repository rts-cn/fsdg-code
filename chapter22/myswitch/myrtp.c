/* File/Codec/RTP Example Author: Seven Du */

#include <switch.h>

int main(int argc, char *argv[])
{
	switch_bool_t verbose = SWITCH_TRUE;
	const char *err = NULL;
	const char *fmtp = "";
	int ptime = 20;
	const char *input = NULL;
	int channels = 1;
	int rate = 8000;
	switch_file_handle_t fh_input = { 0 };
	switch_codec_t codec = { 0 };
	char buf[2048];
	switch_size_t len = sizeof(buf)/2;
	switch_memory_pool_t *pool = NULL;
	int blocksize;
	switch_rtp_flag_t rtp_flags[SWITCH_RTP_FLAG_INVALID] = { 0 };
	switch_frame_t read_frame = { 0 };
	switch_frame_t write_frame = { 0 };
	switch_rtp_t *rtp_session = NULL;
	char *local_addr = "127.0.0.1";
	char *remote_addr = "127.0.0.1";
	switch_port_t local_port = 4444;
	switch_port_t remote_port = 6666;
	char *codec_string = "PCMU";
	int payload_type = 0;
	switch_status_t status;

	if (argc < 2) goto usage;

	input = argv[1];

	if (switch_core_init(SCF_MINIMAL, verbose, &err) != SWITCH_STATUS_SUCCESS) {
		fprintf(stderr, "Cannot init core [%s]\n", err);
		goto end;
	}

	switch_core_set_globals();
	switch_loadable_module_init(SWITCH_FALSE);
	switch_loadable_module_load_module("", "CORE_SOFTTIMER_MODULE", SWITCH_TRUE, &err);
	switch_loadable_module_load_module("", "CORE_PCM_MODULE", SWITCH_TRUE, &err);

	if (switch_loadable_module_load_module((char *) SWITCH_GLOBAL_dirs.mod_dir,
		(char *) "mod_sndfile", SWITCH_TRUE, &err) != SWITCH_STATUS_SUCCESS) {
		fprintf(stderr, "Cannot init mod_sndfile [%s]\n", err);
		goto end;
	}

	/* initialize a memory pool */
	switch_core_new_memory_pool(&pool);

	fprintf(stderr, "Opening file %s\n", input);

	if (switch_core_file_open(&fh_input, input, channels, rate,
		SWITCH_FILE_FLAG_READ | SWITCH_FILE_DATA_SHORT, NULL) != SWITCH_STATUS_SUCCESS) {
		fprintf(stderr, "Couldn't open %s\n", input);
		goto end;
	}

	if (switch_core_codec_init(&codec,
		codec_string, fmtp, rate, ptime, channels,
		SWITCH_CODEC_FLAG_ENCODE, NULL, pool) != SWITCH_STATUS_SUCCESS) {
		fprintf(stderr, "Couldn't initialize codec for %s@%dh@%di\n", codec_string, rate, ptime);
		goto end;
	}

	blocksize = len = (rate * ptime) / 1000;
	switch_assert(sizeof(buf) >= len * 2);
	fprintf(stderr, "Frame size is %d\n", blocksize);

	switch_rtp_init(pool);

	rtp_flags[SWITCH_RTP_FLAG_IO] = 1;
	rtp_flags[SWITCH_RTP_FLAG_NOBLOCK] = 1;
	rtp_flags[SWITCH_RTP_FLAG_DEBUG_RTP_WRITE] = 1;
	rtp_flags[SWITCH_RTP_FLAG_USE_TIMER] = 1;

	rtp_session = switch_rtp_new(local_addr, local_port,
		remote_addr, remote_port,
		payload_type, rate / (1000 / ptime), ptime * 1000,
		rtp_flags, "soft", &err, pool);

	if (!switch_rtp_ready(rtp_session)) {
		switch_log_printf(SWITCH_CHANNEL_LOG, SWITCH_LOG_ERROR, "Can't setup RTP session: [%s]\n", err);
		goto end;
	}

	signal(SIGINT, NULL); /* allow break with Ctrl+C */

	while (switch_core_file_read(&fh_input, buf, &len) ==
		SWITCH_STATUS_SUCCESS) {
		char encode_buf[2048];
		uint32_t encoded_len = sizeof(buf);
		uint32_t encoded_rate = rate;
		unsigned int flags = 0;

		if (switch_core_codec_encode(&codec, NULL, buf, len*2, rate,
			encode_buf, &encoded_len, &encoded_rate, &flags) != SWITCH_STATUS_SUCCESS) {
			fprintf(stderr, "Codec encoder error\n");
			goto end;
		}

		len = encoded_len;
		write_frame.data = encode_buf;
		write_frame.datalen = len;
		write_frame.buflen = len;
		write_frame.rate= 8000;
		write_frame.codec = &codec;
		switch_rtp_write_frame(rtp_session, &write_frame);

		status = switch_rtp_zerocopy_read_frame(rtp_session, &read_frame, 0);

		if (status != SWITCH_STATUS_SUCCESS &&
			status != SWITCH_STATUS_BREAK) {
			goto end;
		}

		len = blocksize;
	}

end:
	switch_core_codec_destroy(&codec);
	if (fh_input.file_interface) switch_core_file_close(&fh_input);
	if (pool) switch_core_destroy_memory_pool(&pool);
	switch_core_destroy();
	return 0;

usage:
	printf("Usage: %s input_file\n\n", argv[0]);
	return 1;
}

/* For Emacs:
 * Local Variables:
 * mode:c
 * indent-tabs-mode:t
 * tab-width:4
 * c-basic-offset:4
 * End:
 * For VIM:
 * vim:set softtabstop=4 shiftwidth=4 tabstop=4 noet:
 */
