# tnx to mamalala
# Changelog
# Changed the variables to include the header file directory
# Added global var for the XTENSA tool root
#
# This make file still needs some work.
#
#
# Output directors to store intermediate compiled files
# relative to the project directory
BUILD_BASE	= build
FW_BASE		= firmware

# Base directory for the compiler
XTENSA_TOOLS_ROOT ?= c:/Espressif/xtensa-lx106-elf/bin

#Extra Tensilica includes from the ESS VM
SDK_EXTRA_INCLUDES ?= c:/Espressif/ESP8266_SDK_094/include
SDK_EXTRA_LIBS ?= c:/Espressif/ESP8266_SDK_094/lib

# base directory of the ESP8266 SDK package, absolute
SDK_BASE	?= c:/Espressif/ESP8266_SDK_094

# esptool path and port
SDK_TOOLS	?= c:/Espressif/utils
ESPTOOL		?= $(SDK_TOOLS)/esptool.exe
ESPPORT		?= COM14

# name for the target project
TARGET		= httpd

# which modules (subdirectories) of the project to include in compiling
#MODULES		= driver user lwip/api lwip/app lwip/core lwip/core/ipv4 lwip/netif
MODULES		= user
EXTRA_INCDIR	= include \
		. \
		lib/heatshrink/ \
		$(SDK_EXTRA_INCLUDES)

# libraries used in this project, mainly provided by the SDK
LIBS		= c gcc hal phy pp net80211 wpa main lwip

# compiler flags using during compilation of source files
CFLAGS		= -Os -g -O2 -std=c99 -Werror -Wpointer-arith -Wundef -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals -D__ets__ -DICACHE_FLASH -Wno-address 

# linker flags used to generate the main object file
LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static

# linker script used for the above linkier step
LD_SCRIPT	= eagle.app.v6.ld

# various paths from the SDK used in this project
SDK_LIBDIR	= lib
SDK_LDDIR	= ld
SDK_INCDIR	= include include/json

# select which tools to use as compiler, librarian and linker
CC		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
OBJCOPY := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-objcopy
OBJDUMP := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-objdump

SRC_DIR		:= $(MODULES)
BUILD_DIR	:= $(addprefix $(BUILD_BASE)/,$(MODULES))

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))

SRC		:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
OBJ		:= $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC))
LIBS		:= $(addprefix -l,$(LIBS))
APP_AR		:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)

LD_SCRIPT	:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT))

INCDIR	:= $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS)  -c $$< -o $$@
endef

.PHONY: all checkdirs clean

all: checkdirs $(TARGET_OUT)

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR) -Wl,--end-group -o $@
	$(vecho) "Run objcopy, please wait..."
	$(Q) $(OBJCOPY) --only-section .text -O binary $@ eagle.app.v6.text.bin
	$(Q) $(OBJCOPY) --only-section .data -O binary $@ eagle.app.v6.data.bin
	$(Q) $(OBJCOPY) --only-section .rodata -O binary $@ eagle.app.v6.rodata.bin
	$(Q) $(OBJCOPY) --only-section .irom0.text -O binary $@ eagle.app.v6.irom0text.bin
	$(vecho) "objcopy done"
	$(vecho) "Run gen_appbin_old.exe"
	$(Q) $(SDK_TOOLS)/gen_appbin_old.exe $@ v6
	$(vecho) "Run gen_flashbin.exe.exe"
	$(Q) $(SDK_TOOLS)/gen_flashbin.exe eagle.app.v6.flash.bin eagle.app.v6.irom0text.bin 0x40000
	$(Q) mv eagle.app.flash.bin firmware/
	$(Q) rm eagle.app.v6.*
	$(Q) rm *.sym
	$(vecho) "Generate eagle.flash.bin successully in folder firmware."
	$(vecho) "eagle.app.flash.bin-------->0x00000"
	$(vecho) "Done"

$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

checkdirs: $(BUILD_DIR) $(FW_BASE)

$(BUILD_DIR):
	$(Q) mkdir -p $@

firmware:
	$(Q) mkdir -p $@

flashonefile: all webpages.espfs
	$(vecho) "Run objcopy, please wait..."
	$(Q) $(OBJCOPY)  --only-section .text -O binary $(TARGET_OUT) eagle.app.v6.text.bin
	$(Q) $(OBJCOPY)  --only-section .data -O binary $(TARGET_OUT) eagle.app.v6.data.bin
	$(Q) $(OBJCOPY)  --only-section .rodata -O binary $(TARGET_OUT) eagle.app.v6.rodata.bin
	$(Q) $(OBJCOPY)  --only-section .irom0.text -O binary $(TARGET_OUT) eagle.app.v6.irom0text.bin
	$(vecho) "objcopy done"
	$(SDK_TOOLS)/gen_appbin_old.exe $(TARGET_OUT) v6
	$(SDK_TOOLS)/gen_flashbin.exe eagle.app.v6.flash.bin $(FW_BASE)/webpages.espfs 0x12000
	rm -f eagle.app.v6.flash.bin
	mv eagle.app.flash.bin eagle.app.v6.flash.bin
	$(SDK_TOOLS)/gen_flashbin.exe eagle.app.v6.flash.bin eagle.app.v6.irom0text.bin 0x40000
	rm -f eagle.app.v6.data.bin
	rm -f eagle.app.v6.flash.bin
	rm -f eagle.app.v6.irom0text.bin
	rm -f eagle.app.v6.rodata.bin
	rm -f eagle.app.v6.text.bin
	rm -f eagle.app.sym
	mv eagle.app.flash.bin $(FW_BASE)/
	$(ESPTOOL) -p $(ESPPORT) -b 256000 write_flash 0x00000 $(FW_BASE)/eagle.app.flash.bin

flash: all
	$(ESPTOOL) -p $(ESPPORT) -b 256000 write_flash 0x00000 $(FW_BASE)/eagle.app.flash.bin

webpages.espfs: firmware cleanwebpages
	cd html; find | ../mkespfsimage/mkespfsimage.exe > ../$(FW_BASE)/webpages.espfs; cd ..

htmlflash: webpages.espfs
	if [ $$(stat -c '%s' $(FW_BASE)/webpages.espfs) -gt $$(( 0x2E000 )) ]; then echo "$(FW_BASE)/webpages.espfs too big!"; false; fi
	$(ESPTOOL) -p $(ESPPORT) -b 256000 write_flash 0x12000 $(FW_BASE)/webpages.espfs

rebuild: clean cleanwebpages all

clean:
	$(Q) rm -f $(APP_AR)
	$(Q) rm -f $(TARGET_OUT)
	$(Q) find $(BUILD_BASE) -type f | xargs rm -f
	$(Q) rm -rf $(BUILD_BASE)
	$(Q) rm -rf $(FW_BASE)
	$(Q) rm -f webpages.espfs

cleanwebpages:
	$(Q) rm -f $(FW_BASE)/webpages.espfs

$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))
