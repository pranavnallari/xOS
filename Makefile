# Tools
ASM  = nasm
QEMU = qemu-system-i386
DD   = dd

# Directories
SRC_DIR  = bootloader
IMG_DIR  = img
BIN_DIR  = bin

# Files
BOOT_SRC = $(SRC_DIR)/boot.s
BOOT_BIN = $(BIN_DIR)/boot.bin
BOOT_IMG = $(IMG_DIR)/bootloader.img

# Default target
all: $(BOOT_IMG)

# Compile bootloader
$(BOOT_BIN): $(BOOT_SRC) | $(BIN_DIR)
	$(ASM) $(BOOT_SRC) -f bin -o $(BOOT_BIN)

# Create floppy image from bootloader binary
$(BOOT_IMG): $(BOOT_BIN) | $(IMG_DIR)
	$(DD) if=$(BOOT_BIN) of=$(BOOT_IMG) bs=512 count=1 conv=notrunc

# Create required directories if they don't exist
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(IMG_DIR):
	mkdir -p $(IMG_DIR)

# Run with QEMU
run: $(BOOT_IMG)
	$(QEMU) -fda $(BOOT_IMG)

# Clean build artifacts
clean:
	rm -rf $(BIN_DIR) $(IMG_DIR)

.PHONY: all clean run
