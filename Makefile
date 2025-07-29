# === Paths ===
SRC_DIR := src/boot
BUILD_DIR := build

BOOT1_SRC := $(SRC_DIR)/boot1.s
STAGE2_SRC := $(SRC_DIR)/stage2.s

BOOT1_BIN := $(BUILD_DIR)/boot1.bin
STAGE2_BIN := $(BUILD_DIR)/stage2.bin
FLOPPY_IMG := $(BUILD_DIR)/floppy.img

# === Tools ===
ASM := nasm
ASMFLAGS := -f bin

QEMU := qemu-system-i386
MCOPY := mcopy
MKFS := mkfs.fat

# === Targets ===

all: $(BOOT1_BIN) $(STAGE2_BIN) $(FLOPPY_IMG)

# Build boot1
$(BOOT1_BIN): $(BOOT1_SRC)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Build stage2
$(STAGE2_BIN): $(STAGE2_SRC)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Create floppy image and copy stage2.bin using mcopy (FAT12)
$(FLOPPY_IMG): $(STAGE2_BIN)
	@mkdir -p $(BUILD_DIR)
	dd if=/dev/zero of=$@ bs=512 count=2880
	$(MKFS) -F 12 $@

	$(MCOPY) -i $@ $(STAGE2_BIN) ::stage2.bin

# Run in QEMU (boot1.bin as boot sector + stage2 loaded via FAT)
run: all
	dd if=$(BOOT1_BIN) of=$(FLOPPY_IMG) bs=512 count=1 conv=notrunc
	$(QEMU) -fda $(FLOPPY_IMG)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) && clear

.PHONY: all clean run
