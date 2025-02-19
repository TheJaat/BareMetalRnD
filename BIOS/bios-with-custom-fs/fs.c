#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define SECTOR_SIZE 512
#define TOTAL_SECTORS 10
#define FS_MAGIC 0x1234

// Use packed structs so the layout is exactly as expected.
typedef struct {
    uint16_t magic;
    uint8_t total_sectors;
    uint8_t root_dir_sector;
} __attribute__((packed)) Superblock;

typedef struct {
    char filename[11];
    uint8_t start_sector;
} __attribute__((packed)) FileEntry;

// Helper: Write one empty (zero-filled) sector.
void write_empty_sector(FILE *fp) {
    uint8_t empty[SECTOR_SIZE] = {0};
    fwrite(empty, SECTOR_SIZE, 1, fp);
}

// Create the disk image filesystem.
void create_filesystem(const char *bootloader, const char *disk_image) {
    FILE *fp = fopen(disk_image, "wb");
    if (!fp) {
        perror("Failed to create disk image");
        return;
    }

    // --- Sector 0: Write the bootloader ---
    FILE *bl = fopen(bootloader, "rb");
    if (!bl) {
        perror("Failed to read bootloader");
        fclose(fp);
        return;
    }
    uint8_t bootloader_data[SECTOR_SIZE] = {0};
    size_t bytes = fread(bootloader_data, 1, SECTOR_SIZE, bl);
    if (bytes < SECTOR_SIZE) {
        // If bootloader is less than 512 bytes, pad with 0.
        memset(bootloader_data + bytes, 0, SECTOR_SIZE - bytes);
    }
    // Write the bootloader
    fwrite(bootloader_data, SECTOR_SIZE, 1, fp);
    fclose(bl);

    // --- Sector 1: Write the Superblock ---
    Superblock sb = {FS_MAGIC, TOTAL_SECTORS, 2};  // file table is in sector 2 (0-based)
    uint8_t sector[SECTOR_SIZE] = {0};
    memcpy(sector, &sb, sizeof(Superblock));
    fwrite(sector, SECTOR_SIZE, 1, fp);

    // --- Sector 2: Write the File Table ---
    // We add one file entry for "hello.txt" whose data is in sector 3.
    FileEntry file = {"hello.txt", 4};  // Here 4 is for the Bootloader which
                                        // uses 1-based sector indexing in CHS.
    memset(sector, 0, SECTOR_SIZE);
    memcpy(sector, &file, sizeof(FileEntry));
    fwrite(sector, SECTOR_SIZE, 1, fp);

    // --- Sector 3: Write the File Data ---
    const char *file_data = "Hello from custom FS!\x00";
    memset(sector, 0, SECTOR_SIZE);
    memcpy(sector, file_data, strlen(file_data) + 1);
    fwrite(sector, SECTOR_SIZE, 1, fp);

    // --- Sectors 4 to TOTAL_SECTORS-1: Write empty sectors ---
    for (int i = 4; i < TOTAL_SECTORS; i++) {
        write_empty_sector(fp);
    }

    fclose(fp);
    printf("Filesystem created successfully: %s\n", disk_image);
}

int main() {
    create_filesystem("boot.bin", "fs.img");
    return 0;
}

