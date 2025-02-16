.PHONY: all clean qemu drive

# Directories
BUILD_DIR = build
OUTPUT_DIR = output

# Compiler and linker definitions
CC        := gcc
CFLAGS    := -Wall -Werror -m64 -mabi=ms -ffreestanding
LFLAGS    := -Wall -Werror -m64 -mabi=ms -nostdlib -shared -Wl,-dll -Wl,--subsystem,10 -e efi_main
UNAME_S   := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
  CC := x86_64-w64-mingw32-gcc
endif
ifeq ($(UNAME_S),Linux)
  CC := x86_64-w64-mingw32-gcc
endif

# Default target: Build UEFI executable, copy OVMF, and set up the drive image.
all: $(BUILD_DIR)/OVMF.fd $(BUILD_DIR)/BOOTX64.EFI drive

# Compile C source files into object files in the build directory.
$(BUILD_DIR)/%.o: %.c
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link object files into the UEFI executable (PE64 EFI format) in the build directory.
$(BUILD_DIR)/BOOTX64.EFI: $(BUILD_DIR)/efimain.o
	$(CC) $^ $(LFLAGS) -o $@

# Copy OVMF firmware to the build directory.
$(BUILD_DIR)/OVMF.fd:
	mkdir -p $(BUILD_DIR)
	cp /usr/share/ovmf/OVMF.fd $(BUILD_DIR)/OVMF.fd

# QEMU target: Launch QEMU with UVMF firmware using the drive image.
qemu:
	sudo qemu-system-x86_64 \
		-bios $(BUILD_DIR)/OVMF.fd \
		-net none \
		-drive format=raw,file=drive.hdd

# Drive target: Set up the FAT32 drive image and copy the UEFI executable into EFI/Boot/ of the output directory.
drive:
	@echo "Setting up the drive file..."
	@if [ ! -f "drive.hdd" ]; then \
	  echo "Creating drive file..."; \
	  dd if=/dev/zero of="drive.hdd" bs=1M count=40; \
	fi; \
	LOOP_DEV=`sudo losetup --find --show "drive.hdd"`; \
	sudo mkfs.vfat "$$LOOP_DEV"; \
	mkdir -p "$(OUTPUT_DIR)"; \
	sudo mount "$$LOOP_DEV" "$(OUTPUT_DIR)"; \
	sudo mkdir -p "$(OUTPUT_DIR)/EFI/Boot"; \
	sudo cp -f $(BUILD_DIR)/BOOTX64.EFI "$(OUTPUT_DIR)/EFI/Boot/"; \
	sleep 3; \
	sudo umount "$(OUTPUT_DIR)"; \
	sudo losetup -d "$$LOOP_DEV"; \
	echo "Done. Press Enter to continue..."; \
	read dummy

# Clean target: Remove generated files.
clean:
	@echo "Cleaning files...."
	rm -rf $(BUILD_DIR) $(OUTPUT_DIR) drive.hdd
	@echo "Done."

