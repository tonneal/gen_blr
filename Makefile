.PHONY: all clean distclean

MAKE := make

NCPU:=1

#NCPU:=$(shell grep -c ^processor /proc/cpuinfo)
#NCPU=$((`grep '^processor' /proc/cpuinfo | wc -l` * 2))

WORK_DIR=$(shell pwd)

PS7_DIR=$(WORK_DIR)/ps7_init
EMBEDDEDSW_DIR=$(WORK_DIR)/embeddedsw
UBOOT_DIR=$(WORK_DIR)/u-boot

FSBL_DIR=$(EMBEDDEDSW_DIR)/lib/sw_apps/zynq_fsbl
FSBL_BSP_DIR=$(FSBL_DIR)/misc
FSBL_SRC_DIR=$(FSBL_DIR)/src


MKBOOTIMG=$(WORK_DIR)/tools/mkbootimage

BOARD=zed

BSP_DIR = $(FSBL_BSP_DIR)/tmp

PS7_OUTPUT=$(PS7_DIR)/output/ps7_init.c


all:fsbl uboot gen_blr

clean: clean_blr clean_uboot clean_fsbl 

fsbl:
ifeq ("$(wildcard $(PS7_OUTPUT))", "") #如果output里没有ps_init.c -> bulid
	$(MAKE) -C $(PS7_DIR) "BOARD=zqv3" "CC=arm-xilinx-eabi-gcc"
	@echo $(FSBL_BSP_DIR)
	mkdir -p $(FSBL_BSP_DIR)/tmp
	@cp -rf $(PS7_DIR)/output/* $(FSBL_BSP_DIR)/tmp/
endif
	$(MAKE) -C $(FSBL_SRC_DIR) BOARD=tmp  CFLAGS=-DFSBL_DEBUG_INFO


clean_fsbl: clean_ps7 clean_embeddedsw

clean_ps7:
	rm -rf $(PS7_DIR)/build
	rm -rf $(PS7_DIR)/output

clean_embeddedsw:
	$(MAKE) -C $(FSBL_SRC_DIR) clean
	rm -rf $(FSBL_BSP_DIR)/tmp/


#-----------------------------------


UBOOT_CONFIG = u-boot/.config
UBOOT_DEFCONFIG = zynq_vvt_rau_defconfig

uboot:
ifeq ("$(wildcard $(UBOOT_CONFIG))", "") 
	$(MAKE) -C $(UBOOT_DIR) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $(UBOOT_DEFCONFIG)
endif
	$(MAKE) -C $(UBOOT_DIR) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

clean_uboot:
	$(MAKE) -C $(UBOOT_DIR) distclean

#-----------------------------------

gen_blr:
	$(MKBOOTIMG) tools/boot.bif BOOT.bin

clean_blr:
	rm -rf BOOT.bin