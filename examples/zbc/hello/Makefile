PICOMOS ?= /opt/picomos
MACHINE ?= zbc

hello.elf: main.c
	mos-clang --config=$(PICOMOS)/share/picomos/configs/picomos-$(MACHINE).cfg \
	          $< -o $@

clean:
	rm -f hello.elf

.PHONY: clean
