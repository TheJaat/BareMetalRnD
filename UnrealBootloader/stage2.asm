;; Stage2
[BITS 16]
[ORG 0x7E00]

stage2_entry:
    mov sp, 0x9c00    ; Set up the stack pointer

    ; Store boot drive number
    mov [BOOT_DRIVE], dl
    ;mov ax, 0x7E00
    ;mov ds, ax

    ;; Print Stage 2 Welcome message
    mov si, WelcomeStage2Message
    call print

    ;; jump to second sector of this stage
    jmp secondSectorCheck
jmp $


; serial print using BIOS VGA
;; To be call from C code
print_C:
    ;push bp
    ;mov bp, sp

    ;mov si, [bp+4]
    ;mov bl, [bp+6]
    mov ah, 0x0E
.print_repeat:
    lodsb
    cmp al, 0
    je .done
    int 0x10

    jmp .print_repeat
.done:
    ;pop bp
    ret
    

; Function to print a newline
newline:
    pusha                ; Save all registers
    mov ah, 0x0e         ; BIOS teletype function
    mov al, 0x0D         ; Carriage Return
    int 0x10             ; Print it
    mov al, 0x0A         ; Line Feed
    int 0x10             ; Print it
    popa                 ; Restore all registers
ret

print:
    pusha
    .loopy:
        lodsb
        or al, al
        jz .done
        mov ah, 0x0e
        mov bx, 7
        int 0x10
        jmp .loopy
    .done:
        call newline
    popa
ret

;; ********************************************************* ;
;; disk address packet format:                               ;
;;                                                           ;
;; Offset | Size | Desc                                      ;
;;      0 |    1 | Packet size                               ;
;;      1 |    1 | Zero                                      ;
;;      2 |    2 | Sectors to read/write                     ;
;;      4 |    4 | transfer-buffer 0xffff:0xffff             ;
;;      8 |    4 | lower 32-bits of 48-bit starting LBA      ;
;;     12 |    4 | upper 32-bits of 48-bit starting LBAs     ;
;; ********************************************************* ;
K_DAP:
.size:
    db     0x10
.zero:
    db     0x00
.sector_count:
    dw     0x0000
.transfer_buffer:
    dw     0x1000          ; temporary location
.transfer_buffer_seg:
    dw     0x0
.lower_lba:
    dd     0xB             ; sector index 11
.higher_lba:
    dd     0x00000000


;; ********************************** ;
;;  Data Area                         ;
;; ********************************** ;
BOOT_DRIVE db 0
KERNEL_SIZE dd 2  ; two sectors
VESA_LOADED db 0
KERNEL_ENTRY dd 0
KERNEL_ADDRESS dd 0x0100000


WelcomeStage2Message: db "Welcome to Stage2", 0

times 512 - ($ - $$) db 0


; LBA extended disk read using BIOS LBA
kernel_load:
    pusha
    mov eax, [KERNEL_SIZE]
    mov [KERNEL_SIZE], eax

kernel_load__:
    ; read 1 sector at a time
    mov ax, 1
    mov [K_DAP.sector_count], ax

    mov ah, 0x42          ; al is unused
    mov al, 0x42          ; al is unused
    mov dl, [BOOT_DRIVE]  ; drive number 0 (OR the drive # with 0x80)
    mov si, K_DAP         ; address of "disk address packet"
    int 0x13
    jc .error
    cmp ah, 0
    jne .error

    ; relocate single sector
    call kernel_relocate

    ; increment sector index
    mov eax, [K_DAP.lower_lba]
    inc eax
    mov [K_DAP.lower_lba], eax

    ; decrement kernel size and loop
    mov eax, [KERNEL_SIZE]
    dec eax
    mov [KERNEL_SIZE], eax
    test eax, eax
    jne kernel_load__

    popa
    ret

.error:
    mov ah, 0x0e
    mov al, 'E'
jmp $

kernel_relocate:
    ; number of dwords to move [512/4]
    mov ecx, 128
    .relocation_loop_start__:
    mov edx, dword [KERNEL_ADDRESS]
    mov ebx, 0x1000

    .relocation_loop__:
    mov eax, dword [ebx]
    mov dword [edx], eax
    add ebx, 4
    add edx, 4

    mov eax, 0
    mov dword [edx], eax

    loop .relocation_loop__
    
    mov dword [KERNEL_ADDRESS], edx
    ret

secondSectorCheck:
    mov ah, 0x0e
    mov al, 'Z'
    int 0x10

    ;call disk_load
    call kernel_load
mov ah, 0x0e
mov al, '3'
int 0x10
;    jmp dword 0xFFFF:0x0010


trampoline:
    ;; Set the ds register
    cli
    xor ax, ax
    mov ds, ax

    ; Load GDT
    lgdt [gdt_desc]

    ; Go to protected mode
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    ; Go to 32-bit code
    jmp 0x08:trampoline32

[BITS 32]
;; 32 Bit land
trampoline32:
    ; Set segment registers
    mov ax, 0x10
    mov es, ax
    mov fs, ax
    mov ds, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x090000 ; set up stack pointer

    ;; Print 5
    mov byte [0xb8000], '5'
    mov byte [0xb8000 + 1], 0x07

    call dword 0x100000; [KERNEL_ENTRY]
    jmp $
    

;;  32 bit GDT
gdt:

gdt_null:
    dd 0
    dd 0

gdt_code:
    dw 0xFFFF
    dw 0
    db 0
    db 10011010b
    db 11001111b
    db 0

gdt_data:
    dw 0xFFFF
    dw 0
    db 0
    db 10010010b
    db 11001111b
    db 0

gdt_end:

gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt

times 10*512 - ($ - $$) db 0
