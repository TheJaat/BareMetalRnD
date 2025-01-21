# Variables
ASM        = nasm
ASFLAGS    = -f bin
OUTPUT_DIR = build
TARGET     = $(OUTPUT_DIR)/stage1.bin
SRC        = stage1.asm

QEMU       = qemu-system-x86_64
QEMU_FLAGS = -drive format=raw,file=build/disk.img

.PHONY: all clean run

# Default target
all: $(OUTPUT_DIR) $(TARGET) disk.img

# Create the build directory if it doesn't exist
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# Compile the bootloader
$(TARGET): $(SRC)
	$(ASM) $(ASFLAGS) -o $@ $<

disk.img:
	@echo "Creating the disk image.."
	dd if=/dev/zero of=build/disk.img bs=512 count=2880
	dd if=build/stage1.bin of=build/disk.img conv=notrunc
	@echo "Disk image created successfully"
# Run the bootloader in QEMU
run: all
	$(QEMU) $(QEMU_FLAGS)

# Clean up build artifacts
clean:
	rm -rf $(OUTPUT_DIR)

