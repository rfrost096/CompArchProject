CC := riscv64-unknown-elf-gcc

CFLAGS := -O2 -std=gnu11 -Wall -specs=htif_nano.specs

SRCDIR := workloads
BINDIR := binaries

all: $(BINDIR)/multiplication_boom.riscv $(BINDIR)/multiplication_rocket.riscv $(BINDIR)/dijkstra_boom.riscv

$(BINDIR)/multiplication_boom.riscv: $(SRCDIR)/multiplication_boom.c
	$(CC) $(CFLAGS) -o $@ $<

$(BINDIR)/multiplication_rocket.riscv: $(SRCDIR)/multiplication_rocket.c
	$(CC) $(CFLAGS) -o $@ $<

$(BINDIR)/dijkstra_boom.riscv: $(SRCDIR)/dijkstra_boom.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean

clean:
	rm -f $(BINDIR)/*.riscv