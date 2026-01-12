CC = clang
CFLAGS = -Wall -O2 -framework IOKit -framework CoreFoundation
TARGET = smc-helper

all: $(TARGET)

$(TARGET): smc.c smc.h
	$(CC) $(CFLAGS) -o $(TARGET) smc.c

clean:
	rm -f $(TARGET)

install: $(TARGET)
	cp $(TARGET) ../../fan/

.PHONY: all clean install
