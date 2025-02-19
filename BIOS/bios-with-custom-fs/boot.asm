; boot.asm
BITS 16
org 0x7C00

%define FS_MAGIC 0x1234
%define BUFFER 0x0500   ; load file data at address 0x7E00

start:
    ; Set up stack and data segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Print "Loading FS..." message
    mov si, load_msg
    call print_string

    ; --- Read the Superblock from Sector 1 ---
    xor ax, ax
    mov es, ax
    mov bx, BUFFER
    mov al, 1         ; number of sectors to read
    mov ch, 0         ; cylinder 0
    mov cl, 2         ; sector 2 (boot sector is sector 1) (1-based indexing)
    mov dh, 0         ; head 0
    mov dl, 0x80      ; boot drive (first hard disk)
    call disk_read

    ; Check magic number in the superblock
    cmp word [BUFFER], FS_MAGIC
    jne halt
    
    mov si, valid_superblock
    call print_string

    ; --- Read the File Table from Sector 2 ---
    mov bx, BUFFER
    mov al, 1         ; read 1 sector
    mov ch, 0
    mov cl, 3         ; sector 3: file table, (1-based indexing)
    mov dh, 0
    mov dl, 0x80
    call disk_read
    
    mov si, read_file_table
    call print_string

    ; Our file table is a single FileEntry:
    ; FileEntry structure: 8-byte filename, then 1 byte for start_sector.
    ; Get the start sector from offset 8.
    mov cl, byte [BUFFER + 11]

    ; --- Read the File Data from the indicated sector ---
    mov bx, BUFFER
    mov al, 1         ; read 1 sector
    mov ch, 0
    ; cl already holds the file data sector number (from the file table)
    mov dh, 0
    mov dl, 0x80
    call disk_read

    ; --- Print the file contents (assumed to be a null-terminated string) ---
    mov si, BUFFER
    call print_string

halt:
    cli
    hlt

;---------------------------
; print_string: prints a null-terminated string pointed to by SI
;---------------------------
print_string:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

;---------------------------
; disk_read: reads sectors from disk using BIOS interrupt 0x13.
; Expected registers before call:
;   BX = buffer address (physical address; here we use 0x7E00)
;   AL = number of sectors to read
;   CH = cylinder, CL = sector, DH = head, DL = drive
;---------------------------
disk_read:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x02
    int 0x13
    jc disk_fail
    pop dx
    pop cx
    pop bx
    pop ax
    ret
disk_fail:
    mov si, disk_err
    call print_string
    jmp halt

;---------------------------
load_msg:   db "Loading FS...", 0x0d, 0x0a, 0
disk_err:   db "Disk read error!",0x0d, 0x0a, 0
valid_superblock: db "Valid SuperBlock", 0x0d, 0x0a, 0
read_file_table: db "Read the file table", 0x0d, 0x0a, 0

; Pad to 510 bytes, then add boot signature 0xAA55
times 510 - ($ - $$) db 0
dw 0xAA55

