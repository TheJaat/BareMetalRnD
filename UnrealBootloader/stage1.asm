[BITS 16]
[ORG 0x7c00]
;; 0x7c00 is the place where the BIOS loads this bootsector
;; code and hands over the control

;; First stage bootloader.
;; DL is set by BIOS with the drive number.
main_gate:
    jmp start

;; ****************************************
;; Header includes
;; ****************************************
%include "common.inc"

start:
    xor ax, ax    ; Clear the ax register
    mov ds, ax    ; Set up the data segment register
    mov ss, ax    ; Set up the stack segment register
    mov sp, 0x7c00 ; Set the stack pointer
    mov [BOOT_DRIVE], dl    ; Save disk identity number to variable

mov ah, 0x0e
mov al, '1'
int 0x10


;; By entering unreal mode, we can access memory beyond
;; the normal ~1mb scope and correcly relocate the kernel.
enable_unreal_mode:
    xor ax, ax        ; Clear out the AX register
    mov ds, ax        ; Set up the data segment register
    mov ss, ax        ; Set up the stack segment register
    mov sp, 0x9c00    ; 2000h past code start,
                      ; making the stack 7.5k in size

    cli    ; Disable the hardware interrupts
    push ds    ; Save real mode data segment 

    lgdt [gdtinfo]    ; Load the gdt

    ;; Enable protection bit
    mov  eax, cr0
    or al, 1
    mov  cr0, eax

    ;; Jump to the protected land
    jmp 0x8:pmode

;; Protected Land
pmode:
    mov bx, 0x10    ; The offset of the third entry in the gdt table,
                    ; which is data segment selector
    mov ds, bx      ; Set the data segment to the offset 0x10 in the gdt

    ;; Revert back the protection bit
    and al, 0xFE           
    mov cr0, eax

    ;; Jump back to real mode making it unreal mode
    jmp 0x0:unreal    ; return to real mode

unreal:
    pop ds    ; get back old segment

;    sti
    cli

; Enable a20 line
enable_a20_line:
    push bp
    mov bp, sp
    in al, 0xee
    mov sp, bp
    pop bp

enable_a20_bios:
    mov ax, 2403h
    int 15h
    jb a20_no_support
    cmp ah, 0
    jnz a20_no_support

    mov ax, 2402h
    int 15h
    jb a20_failed
    cmp ah, 0
    jnz a20_failed

    cmp al, 1
    jz a20_activated

    mov ax, 2401h
    int 15h
    jb a20_failed
    cmp ah, 0
    jnz a20_failed

    a20_failed:
    a20_no_support:
    a20_activated:


mov ah, 0x0e
mov al, '2'
int 0x10

;; Load the stage 2
call stage_load


    ;; Save the boot drive identity into the dl register
    ;; to be used in stage 2
    mov dl, [BOOT_DRIVE]

    ;; Jump to stage 2
    jmp dword 0x7e00

;; Load Stage 2
stage_load:
stage_load__:
    mov dl, [BOOT_DRIVE]         ; Set dl to boot drive number
    mov cl, STAGE2_START_INDEX   ; Sector index, 2
    mov ah, 0x02                 ; BIOS read function
    mov bx, 0x7e00               ; Memory location
    mov al, STAGE2_SECTORS       ; Number of sectors to read, 10
    mov dh, 0                    ;
    mov ch, 0
    int 0x13                     ; BIOS Disk read interrupt

    or ah, ah                    ; error flag
    jnz stage_load__             ; failed = hang

    cmp al, STAGE2_SECTORS       ; how many sectors?
    jne stage_load__             ; failed = hang

ret

BOOT_DRIVE db 0
gdtinfo:
   dw gdt_end - gdt - 1   ; last byte in table
   dd gdt                 ; start of table
gdt:        dd 0,0        ; entry 0 is always unused
codedesc:   db 0xff, 0xff, 0, 0, 0, 10011010b, 00000000b, 0
flatdesc:   db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
gdt_end:

WelcomeStage1Message: db "Welcome to Stage1", 0

TIMES 510 - ($ - $$) db 0 ; Fill the rest of sector with 0
DW 0xaa55 ; Add boot signature at the end of bootloader
