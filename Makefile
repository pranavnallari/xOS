# ====== Tools ======
ASM  = nasm
QEMU = qemu-system-i386
DD   = dd

# ====== Directories ======
SRC_DIR  = bootloader
IMG_DIR  = img
BIN_DIR  = bin

# ====== Files ======
BOOT_SRC = $(SRC_DIR)/boot.s
GDT_SRC  = $(SRC_DIR)/gdt.s
BOOT_BIN = $(BIN_DIR)/boot.bin
BOOT_IMG = $(IMG_DIR)/OS.img

# ====== Default Target ======
all: $(BOOT_IMG)

# ====== Compile Bootloader ======
$(BOOT_BIN): $(BOOT_SRC) $(GDT_SRC) | $(BIN_DIR)
	$(ASM) $(BOOT_SRC) -f bin -o $(BOOT_BIN)

# ====== Create Floppy Image ======
$(BOOT_IMG): $(BOOT_BIN) | $(IMG_DIR)
	$(DD) if=$(BOOT_BIN) of=$(BOOT_IMG) bs=512 count=1 conv=notrunc status=none

# ====== Ensure Directories Exist ======
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(IMG_DIR):
	mkdir -p $(IMG_DIR)

# ====== Run with QEMU ======
run: $(BOOT_IMG)
	$(QEMU) -fda $(BOOT_IMG)

# ====== Clean Build Artifacts ======
clean:
	rm -rf $(BIN_DIR) $(IMG_DIR)

.PHONY: all clean run
