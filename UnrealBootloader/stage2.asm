;; Stage2
[BITS 16]
[ORG 0x7E00]

stage2_gate:
jmp stage2_entry

;; ****************************************
;; Header includes
;; ****************************************
%include "common.inc"
%include "utils16.inc"
;; ----------------------------------------

stage2_entry:
    mov sp, 0x9c00    ; Set up the stack pointer

    ; Store boot drive number
    mov [BOOT_DRIVE], dl

    ;; Print Stage 2 Welcome message
    mov si, WelcomeStage2Message
    call PrintString16

    ;; Load the kernel
    call LoadKernel

    ;; The word trampoline used in specific situations such as
    ;; transitioning between different modes
    ;; Here it transitions to 32 bit mode
    call Trampoline

jmp $


; LBA extended disk read using BIOS LBA
LoadKernel:
    pusha                     ; Save all registers state to ensure no data is lost

    ; Get the Kernel Size in eax
    mov eax, [KERNEL_SIZE]             ; Load the size of the kernel (in sectors)
    ;mov [KERNEL_SIZE], eax

kernel_load__:
    ; Read 1 sector at a time
    mov ax, 1                          ; Set AX to 1 (indicating we are reading 1 sector)
    mov [K_DAP.sector_count], ax       ; Store 1 as the sector count in the Disk Address
                                       ; Packet (DAP)

    ; Set up the BIOS LBA extended read
    mov ah, 0x42                       ; BIOS interrupt 0x13 function for LBA read
    mov al, 0x42                       ; AL is unused, set to 0x42 for clarity
    mov dl, [BOOT_DRIVE]               ; Load the drive number
    mov si, K_DAP                      ; Load the address of the Disk Address Packet (DAP)
                                       ; into  SI
    int 0x13                           ; Call BIOS interrupt for LBA disk read

    jc .error                          ; If the carry flag is set, jump to the
                                       ; error handler
    cmp ah, 0                          ; Check if AH (error code) is zero
    jne .error                         ; If AH is non-zero, jump to the error handler

    ; Relocate the loaded sector
    Call RelocateKernel

    ; Increment the sector index
    mov eax, [K_DAP.lower_lba]         ; Load the current LBA (Logical Block Address)
                                       ; into EAX
    inc eax                            ; Increment the LBA to the next sector
    mov [K_DAP.lower_lba], eax         ; Store the incremented LBA back in the
                                       ; Disk Address Packet

    ; Decrement the remaining kernel size and loop if more sectors to load
    mov eax, [KERNEL_SIZE]             ; Load the remaining kernel size into EAX
    dec eax                            ; Decrement the kernel size by 1
    mov [KERNEL_SIZE], eax             ; Store the updated kernel size
    test eax, eax                      ; Check if the kernel size is zero
    jne kernel_load__                  ; If not zero, jump back to load the next sector

    popa                               ; Restore all previously saved registers
ret                                    ; Return to the caller

.error:
    ; Print the error message
    mov si, KernelLoadingFailureMessage
    call PrintString16
    hlt
    jmp $


;; Relocate the kernel to a new memory location
RelocateKernel:
    ; Number of DWORDS to move (512 bytes / 4 bytes per DWORD = 128)
    mov ecx, 128                         ; Set the loop counter (ECX) for 128 iterations

    .relocation_loop_start__:
         ; Initialize pointers for source and destination
         mov edx, dword [KERNEL_ADDRESS]      ; Load the destination address (current
                                              ; kernel address) into EDX
         mov ebx, 0x1000                      ; Set the source address to 0x1000 (start
                                              ; of loaded kernel)

         .relocation_loop__:
             ; Copy DWORD from source to destination
             mov eax, dword [ebx]             ; Load a DWORD from the source (EBX) into
                                              ; EAX
             mov dword [edx], eax             ; Store the DWORD into the destination
                                              ; address (EDX)

             ; Increment pointers by 4 (size of a DWORD)
             add ebx, 4                       ; Move source pointer to the next DWORD
             add edx, 4                       ; Move destination pointer to the next DWORD

             ; Clear the destination address
             mov eax, 0                       ; Load 0 into EAX
             mov dword [edx], eax             ; Write 0 to the current destination address (
                                              ; optional padding)

         ; Loop until all DWORDs are moved
         loop .relocation_loop__              ; Decrement ECX and repeat until it reaches zero

         ; Update the Kernel Address to the next location
         mov dword [KERNEL_ADDRESS], edx      ; Update KERNEL_ADDRESS to the new location
ret


Trampoline:
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
    jmp 0x08:Trampoline32

[BITS 32]
;; 32 Bit land
Trampoline32:
    ; Set segment registers
    mov ax, 0x10
    mov es, ax
    mov fs, ax
    mov ds, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x090000 ; set up stack pointer

    ;; Debugging purpose, print 5
;    mov byte [0xb8000], '5'
;    mov byte [0xb8000 + 1], 0x07

    call dword [KERNEL_ENTRY]
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
KERNEL_SIZE dd 2024  ; 2048 sectors, means 1 MB
VESA_LOADED db 0
KERNEL_ENTRY dd 0x0100000
KERNEL_ADDRESS dd 0x0100000

WelcomeStage2Message: db "Welcome to Stage2", 0
KernelLoadingFailureMessage: db "Failure in loading the kernel", 0

times 10*512 - ($ - $$) db 0
