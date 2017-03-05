SHELL		=  /bin/bash
EMULATIONBAUD	=  9600
ESPPORT		?= /dev/ttyUSB0

ESPTOOL		=  /opt/esptool/esptool.py
ZASM		=  /usr/local/bin/zasm
SERIAL		=  /usr/bin/putty

FLAGSHEX	= --z80 -v2 -u -w -x
FLAGSBIN	= --z80 -v2 -u -w -b

TARGET		= SED80

all: $(TARGET).hex 

$(TARGET).hex: $(TARGET).Z80
	@echo [ZASM] $<
	@$(ZASM) $(FLAGSHEX) $< -o $@
	@srec_cat $@ -intel -offset 0x100 -o /tmp/zasm.tmp -intel
	@tail -n +2 /tmp/zasm.tmp > $@

flash: $(TARGET).hex
	@echo -n [HEX UPLOAD] Reset...
	@$(ESPTOOL) --baud $(EMULATIONBAUD) --port $(ESPPORT) --chip esp8266 --no-stub --after soft_reset read_mac > /dev/null
	@sleep 0.5
	@echo -n Boot...
	@echo "B" > /dev/ttyUSB0
	@sleep 0.2
	@echo -n CD...
	@echo "I:" > /dev/ttyUSB0
	@sleep 0.2
	@echo -n PIP...
	@echo "A:PIP I:$(TARGET).HEX=CON:" > /dev/ttyUSB0
	@sleep 0.2
	@echo -n UPLOAD ---%
	@$(eval LINES=$(shell cat $(TARGET).hex | wc -l))
	@cnt=0;cat $(TARGET).hex | while read line;do cnt=$$(( cnt+100)); printf "\b\b\b\b%3d%%" $$(( $$cnt/$(LINES) )); echo $$line>/dev/ttyUSB0;sleep 0.01; done
	@echo -n " "
	@echo -e "\x1A" > /dev/ttyUSB0
	@echo HEX2COM...
	@sleep 2
	@echo "A:LOAD $(TARGET)" > /dev/ttyUSB0
	@echo -n "SED80 TESTFILE.TXT" > /dev/ttyUSB0
	@$(SERIAL) -load cpm8266 -sercfg $(EMULATIONBAUD)
		
clean:
	@rm -rf *~
	@rm -rf *.{rom,bin,hex,lst}


