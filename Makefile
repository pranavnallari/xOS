# ====== Tools ======
ASM  = nasm
QEMU = qemu-system-i386
DD   = dd

# ====== Directories ======
SRC_DIR     = src/boot
BIN_DIR     = build/bin
IMG_DIR     = build/img

# ====== Files ======
BOOT_SRC    = $(SRC_DIR)/boot1.s

BOOT_BIN    = $(BIN_DIR)/boot.bin

BOOT_IMG    = $(IMG_DIR)/OS.img

# ====== Default Target ======
all: $(BOOT_IMG)

# ====== Compile Bootloader and Stage2 ======
$(BOOT_BIN): $(BOOT_SRC) | $(BIN_DIR)
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)


# ====== Create Disk Image ======
$(BOOT_IMG): $(BOOT_BIN) | $(IMG_DIR)
	dd if=$(BOOT_BIN) of=$(BOOT_IMG) bs=512 count=1 conv=notrunc status=none

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
