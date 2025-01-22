BITS 16

ORG 0x100000  ; Logical address at 0x100000 (physical: 0x1000:0x0000)

stage2_entry:
    ;; Set up data segment
    ;; It is important 
    mov ax, 0x1000       ; Set data segment to 0x1000
    mov ds, ax
    
    ;; Print the stage 2 welcome message
    mov si, stage2Msg
    call print

jmp $    ; Infinite loop to halt execution


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

; prints message in register si
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


times 512 - ($ - $$) db 0    ; (Padded to 512 bytes - 1 sector)


;; Data Area
stage2Msg: db "Welcome to Stage2", 0

times 1024 - ($ - $$) db 0    ; (Padded to 1 KB - 2 Sectors)
