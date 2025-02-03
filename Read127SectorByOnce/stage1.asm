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
%include "utils16.inc"

%define STAGE2 0x7e00

;; ----------------------------------------


    ; ========================= Memory Layout ================================
    ;_________________________________________________________________________
    ;  Address Range    |     Size     | Purpose
    ;_________________________________________________________________________
    ; 0x00000 - 0x003FF |     1 KB     | Interrupt Vector Table (IVT)
    ;                   |              | Stores interrupt vectors, with each
    ;                   |              | entry being 4 bytes (16-bit segment:
    ;                   |              | offset pairs). Used by BIOS and
    ;                   |              | system interrupts.
    ;-------------------|--------------|---------------------------------------
    ; 0x00400 - 0x004FF |    256 bytes | BIOS Data Area (BDA): Contains BIOS
    ;                   |              | settings such as disk drive info,
    ;                   |              | keyboard buffer, video mode data, etc.
    ;-------------------|--------------|---------------------------------------
    ; 0x00500 - 0x07BFF | 30.75 bytes  | Free Conventional Memory: Usable for
    ;                   |              | program data, stack or temporary
    ;                   |              | storage.
    ;-------------------|--------------|---------------------------------------
    ; 0x07C00 - 0x07DFF |   512 bytes  | Boot Sector: The BIOS loads the boot
    ;                   |              | sector of the bootable disk here.
    ;                   |              | Reserved for stage 1 of the bootloader.
    ;-------------------|--------------|----------------------------------------
    ; 0x07E00 - 0x9FFFF | ~600 KB      | Extended Conventional Memory: Free
    ;                   |              | space for user programs. Stage 2 can be
    ;                   |              | loaded in this region.
    ;-------------------|--------------|----------------------------------------
    ; 0xA0000 - 0xBFFFF | 128 KB       | Video RAM: Memory Mapped for video
    ;                   |              | adapters like VGA. Should not be
    ;                   |              | overwritten.
    ;-------------------|--------------|----------------------------------------
    ; 0xC0000 - 0xDFFFF | 128 KB       | Option ROMs: Contains additional
    ;                   |              | firware for peripherals like video
    ;                   |              | cards and network cards.
    ;-------------------|--------------|----------------------------------------
    ; 0xE0000 - 0xFFFFF | 128 KB       | BIOS ROM: Contains the system BIOS,
    ;                   |              | responsible for low-level hardware
    ;                   |              | initialization. Read-only.
    ;---------------------------------------------------------------------------

start:
    xor ax, ax             ; Clear the ax register
    mov ds, ax             ; Set up the data segment register
    mov ss, ax             ; Set up the stack segment register
    mov sp, 0x7c00         ; Set the stack pointer
    mov [BOOT_DRIVE], dl   ; Save disk identity number to variable

    ;; Clear the screen
    call ClearScreen

    ;; Print the stage1 welcome message
    mov si, WelcomeStage1Message
    call PrintString16

    ;; Load Stage2
    call ReadSectors

    ;; Set up the GDT
    call SetupGDT

    ;; Jump to protected mode
    jmp CODESEG:pmode


hlt

;; ****************************************************
ReadSectors:
    mov cx, 10    ; Counter variable

    .loop:
        push cx
        
        ; Read Extended Sectors
        mov ah, 0x42
        mov si, dap
        int 0x13
        jc DiskReadError

        ; Modify DAP for next Read
        add dword [dap + 8], 127
        add word [dap + 6], 0xFE0
        
        pop cx
        
        ; Loop until cx is not 0
        loop .loop
    ret


DiskReadError:
    mov si, DiskReadErrorMessage
    call PrintString16
cli
hlt
jmp $

SetupGDT:
    ; Disable interrupts
    cli

    ; Load GDT Address
    lgdt [GDTR]

    ; Enable Protected Mode
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

ret

[BITS 32]
pmode:
    mov ax, DATASEG

    ; Setup registers with the GDT offset
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Setup x86 Stack
    mov ebp, 0x90000
    mov esp, ebp
    mov ss, ax

    jmp 0x7e00    ; Jump to the stage2


[BITS 16]

;; ****************************************************
;; Data Variables
;; ----------------------------------------------------
BOOT_DRIVE db 0    ; For storing the disk identity number
WelcomeStage1Message: db "Welcome to Stage1", 0
DiskReadErrorMessage: db "Disk Read Error", 0

; === Data Section ===
dap:
.size:                db 16              ; Size of DAP (always 16 bytes)
.zero:                db 0               ; Reserved
.sector_count:        dw 0x7F            ; Number of sectors to read
.transfer_buffer:     dw 0x0000          ; Offset
.transfer_buffer_seg: dw STAGE2 >> 4     ; Segment
.lower_lba:           dq 1               ; LBA (start)        
;.higher_lba:          dd 0              ; Upper 32 bits of LBA
;; ----------------------------------------------------

GDT:
    ; Not Used
    GDT.Null:
        dd  0x00
        dd  0x00

    ; Code Segment
    GDT.Code:
        ; Segment Limit
        dw  0xFFFF

        ; Base
        dw  0x00
        db  0x00

        ; 1001 1010b (Executable, R/W, Code Segment)
        db  0x9A

        ; Additional Attributes
        db  0xCF

        ; Reserved
        db  0x00

    GDT.Data:
        ; Segment Limit
        dw  0xFFFF

        ; Base
        dw  0x00
        db  0x00

        ; Specifies Data Segment
        db  0x92

        ; Additional Attributes
        db  0xCF

        ; Reserved
        db  0x00

; GDT Struct to Store Address and Limit
GDTR:
        dw GDTR - GDT - 1
        dd GDT

; Segments definitions
CODESEG equ GDT.Code - GDT
DATASEG equ GDT.Data - GDT


TIMES 510 - ($ - $$) db 0 ; Fill the rest of sector with 0, Padding
DW 0xaa55 ; Add boot signature at the end of bootloader
