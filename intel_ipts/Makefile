#
# Makefile - Intel Precise Touch & Stylus device driver
# Copyright (c) 2016, Intel Corporation.
#

CC=gcc
CFLAGS=-c -Wall -O2
#LDFLAGS=-lncurses
SOURCES=intel-ipts.c ipts-mei.c ipts-hid.c ipts-msg-handler.c ipts-kernel.c ipts-resource.c ipts-gfx.c ipts-dbgfs.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=intel-ipts

all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(OBJECTS) $(EXECUTABLE)
