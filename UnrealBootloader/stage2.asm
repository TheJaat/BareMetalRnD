[BITS 16]
[ORG 0x7E00]
; first instruction adress

; bootloader stage 2 begin
.start:

mov sp, 0x9c00
; BIOS boot drive in dl
mov [BOOT_DRIVE], dl
;mov ax, 0x7E00
;mov ds, ax


mov si, WelcomeStage1Message
call print

jmp check
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
; =================================================================== ;
; disk address packet format:                                         ;
;                                                                     ;
; Offset | Size | Desc                                                ;
;      0 |    1 | Packet size                                         ;
;      1 |    1 | Zero                                                ;
;      2 |    2 | Sectors to read/write                               ;
;      4 |    4 | transfer-buffer 0xffff:0xffff                       ;
;      8 |    4 | lower 32-bits of 48-bit starting LBA                ;
;     12 |    4 | upper 32-bits of 48-bit starting LBAs               ;
; =================================================================== ;
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


BOOT_DRIVE db 0
KERNEL_SIZ dd 0
VESA_LOADED db 0
KERNEL_ENTRY dd 0
KERNEL_ADDRESS dd 0x0100000


WelcomeStage1Message: db "Welcome to Stage2", 0


check:

mov ah, 0x0e
mov al, 'Z'
int 0x10
jmp $

times 1024 - ($ - $$) db 0
