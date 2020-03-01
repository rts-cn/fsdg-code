import freeswitch

def handler(session, args):
	session.answer()
	session.sleep(1000);
	session.streamFile("/tmp/hello-python.wav");
	session.hangup();
