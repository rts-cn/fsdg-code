FS  = /usr/local/freeswitch
INC = -I$(FS)/include
LIB = -L$(FS)/lib

all: myswitch myrtp

myswitch: myswitch.c
	gcc -o myswitch -ggdb $(INC) $(LIB) -lfreeswitch myswitch.c

myrtp: myrtp.c
	gcc -o myrtp -ggdb $(INC) $(LIB) -lfreeswitch myrtp.c

clean:
	rm -rf myswitch myswitch.so myswitch.dSYM myrtp myrtp.so myrtp.dSYM
