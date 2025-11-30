CC := riscv64-unknown-elf-gcc

CFLAGS := -O2 -std=gnu11 -Wall -specs=htif_nano.specs

all: multiplication_boom.riscv multiplication_rocket.riscv

multiplication_boom.riscv: multiplication_boom.c
	$(CC) $(CFLAGS) -o $@ $<

multiplication_rocket.riscv: multiplication_rocket.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean

clean:
	rm -f *.riscv