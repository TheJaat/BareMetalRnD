BITS 16

ORG 0x100000  ; Logical address at 0x100000 (physical: 0x1000:0x0000)
;ORG 0x0500
stage2_entry:
    ;; Set up data segment
    ;; It is important 
    mov ax, 0x1000       ; Set data segment to 0x1000
    mov ds, ax
mov si, stage2Msg
call print
jmp $
;mov ah, 0x0e
;mov al, 'M'
;int 0x10
;jmp $

 ; Set up segment registers
;    mov ax, 0x10      ; Data segment selector (flat memory model)
;    mov ds, ax
;    mov es, ax
;    mov fs, ax
;    mov gs, ax
;    mov ss, ax

    ; Set up the stack
;    mov esp, 0x90000  ; Stack top (adjust as needed)
;    mov ebp, esp
 
    
    mov edi, 0xb8000      ; VGA text mode memory address
    mov eax, 0x0741       ; 'A' with light gray on black
    mov [edi], eax        ; Write character to top-left of the screen

    
;    mov edi, 0xb8000
;    mov al, 'M'
;    mov ah, 0x07
;    mov [es:edi], ax

    ;mov ah, 0x0e
    ;mov al, 'M'
    ;int 0x10
    
    ;; Print the stage 2 welcome message
    ;mov si, stage2Msg
    ;call print

jmp $    ; Infinite loop to halt execution



times 512 - ($ - $$) db 0    ; (Padded to 512 bytes - 1 sector)

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


;; Data Area
stage2Msg: db "Welcome to Stage2", 0

times 1024 - ($ - $$) db 0    ; (Padded to 1 KB - 2 Sectors)
