VIVADO := vivado -nolog -nojournal -mode batch -source 
TARGET := 

BOARD=

PHONY := all

all:
	$(VIVADO) apply_ps.tcl -tclargs $(BOARD)

.PHONY :clean
clean:
	@rm -rf build output *.hdf *.jou *.log

.PHONY :install 
install:
	echo $(shell pwd)
	echo $(INSTALL_DIR)
	@cp ./output/* $(INSTALL_DIR)
