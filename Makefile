# ====== Tools ======
ASM  = nasm
QEMU = qemu-system-i386
DD   = dd

# ====== Directories ======
SRC_DIR     = bootloader
KERNEL_DIR  = kernel
BIN_DIR     = bin
IMG_DIR     = img

# ====== Files ======
BOOT_SRC    = $(SRC_DIR)/boot.s
GDT_SRC     = $(SRC_DIR)/gdt.s
KERNEL_SRC  = $(KERNEL_DIR)/kernel.s

BOOT_BIN    = $(BIN_DIR)/boot.bin
KERNEL_BIN  = $(BIN_DIR)/kernel.bin
BOOT_IMG    = $(IMG_DIR)/OS.img

# ====== Default Target ======
all: $(BOOT_IMG)

# ====== Compile Bootloader and Kernel ======
$(BOOT_BIN): $(BOOT_SRC) $(GDT_SRC) | $(BIN_DIR)
	$(ASM) -I$(SRC_DIR)/ -f bin $(BOOT_SRC) -o $(BOOT_BIN)

$(KERNEL_BIN): $(KERNEL_SRC) | $(BIN_DIR)
	$(ASM) -I$(KERNEL_DIR)/ -f bin $(KERNEL_SRC) -o $(KERNEL_BIN)

# ====== Create Disk Image ======
$(BOOT_IMG): $(BOOT_BIN) $(KERNEL_BIN) | $(IMG_DIR)
	$(DD) if=$(BOOT_BIN) of=$(BOOT_IMG) bs=512 count=1 conv=notrunc status=none
	$(DD) if=$(KERNEL_BIN) of=$(BOOT_IMG) bs=512 seek=1 conv=notrunc status=none

# ====== Ensure Directories ======
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(IMG_DIR):
	mkdir -p $(IMG_DIR)

# ====== Run with QEMU ======
run: $(BOOT_IMG)
	$(QEMU) -fda $(BOOT_IMG)

# ====== Clean ======
clean:
	rm -rf $(BIN_DIR) $(IMG_DIR) && clear

.PHONY: all clean run
