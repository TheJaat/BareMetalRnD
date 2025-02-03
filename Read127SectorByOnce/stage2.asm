BITS 32
ORG 0x7e00

stage2:
    ; Set up segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax

    ; Set up the stack
    mov esp, 0x7c00    ; Stack grows downward from 0x7c00

    mov esi, message
    call print_string

    ; Halt the CPU
    cli
    hlt

print_string:
    mov edi, 0xB8000
    mov ah, 0x0f

    .print_loop:
        lodsb
        or al, al
        jz .done
        
        stosw
        jmp .print_loop
    .done:
        ret

;times 512*127*10 - ($ - $$) db 0

message db "Hello, 32-bit Protected Mode!", 0

times 512*127*10 - ($- $$) db 0
