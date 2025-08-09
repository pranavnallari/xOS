# === Paths ===
BOOT_DIR     := src/boot
BUILD_DIR    := build

BOOT1_SRC    := $(BOOT_DIR)/boot1.s
STAGE2_SRC   := $(BOOT_DIR)/stage2.s

STDIO_INC    := $(BOOT_DIR)/stdio.inc
GDT_INC      := $(BOOT_DIR)/gdt.inc
A20_INC      := $(BOOT_DIR)/a20.inc

BOOT1_BIN    := $(BUILD_DIR)/boot1.bin
STAGE2_BIN   := $(BUILD_DIR)/stage2.bin
FLOPPY_IMG   := $(BUILD_DIR)/floppy.img

# === Tools ===
ASM          := nasm
ASMFLAGS     := -f bin

QEMU         := qemu-system-i386
QEMU_FLAGS   := -fda $(FLOPPY_IMG) -s -S

MCOPY        := mcopy
MKFS         := mkfs.fat

# === Targets ===

all: $(BOOT1_BIN) $(STAGE2_BIN) $(FLOPPY_IMG)

# Build boot1
$(BOOT1_BIN): $(BOOT1_SRC)
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Build stage2
$(STAGE2_BIN): $(STAGE2_SRC) $(STDIO_INC) $(GDT_INC) $(A20_INC)
	@mkdir -p $(BUILD_DIR)
	$(ASM) -I $(BOOT_DIR) $(ASMFLAGS) -o $@ $<

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

# Debug mode with GDB
debug: ASMFLAGS := -f bin -g -F dwarf
debug: all
	dd if=$(BOOT1_BIN) of=$(FLOPPY_IMG) bs=512 count=1 conv=notrunc
	$(QEMU) $(QEMU_FLAGS) & \
	sleep 1 && \
	gdb -ex "target remote localhost:1234" \
	    -ex "set architecture i8086" \
	    -ex "break *0x7c00" \
	    -ex "continue"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	clear

.PHONY: all clean run debug
