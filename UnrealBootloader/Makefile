# Variables
ASM        = nasm
ASFLAGS    = -f bin
OUTPUT_DIR = build
STAGE1_SRC        = stage1.asm
STAGE1_BIN     = $(OUTPUT_DIR)/stage1.bin

STAGE2_SRC = stage2.asm
STAGE2_BIN = $(OUTPUT_DIR)/stage2.bin

KERNEL_SRC = kernel.asm
KERNEL_BIN = $(OUTPUT_DIR)/kernel.bin

DISK_IMG   = $(OUTPUT_DIR)/disk.img

QEMU       = qemu-system-x86_64
QEMU_FLAGS = -drive format=raw,file=$(DISK_IMG)

.PHONY: all clean run

# Default target
all: $(OUTPUT_DIR) $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN) $(DISK_IMG)

# Create the build directory if it doesn't exist
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# Compile stage1
$(STAGE1_BIN): $(STAGE1_SRC) | $(OUTPUT_DIR)
	$(ASM) $(ASFLAGS) -o $@ $<

# Compile stage2
$(STAGE2_BIN): $(STAGE2_SRC) | $(OUTPUT_DIR)
	$(ASM) $(ASFLAGS) -o $@ $<

# Compile kernel.bin
$(KERNEL_BIN) : $(KERNEL_SRC) | $(OUTPUT_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Create the disk image
$(DISK_IMG): $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN) | $(OUTPUT_DIR)
	@echo "Creating the disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=$(STAGE1_BIN) of=$@ bs=512 conv=notrunc
	dd if=$(STAGE2_BIN) of=$@ bs=512 seek=1 conv=notrunc
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=11 conv=notrunc
	@echo "Disk image created successfully."

# Run the bootloader in QEMU
run: $(DISK_IMG)
	$(QEMU) $(QEMU_FLAGS)
	# qemu-system-i386 -drive format=raw,file=build/disk.img

# Clean up build artifacts
clean:
	rm -rf $(OUTPUT_DIR)
