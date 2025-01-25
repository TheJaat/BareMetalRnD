BITS 32
ORG 0x100000

kmain:
    ;; Print K letter
    mov byte [0xb8000], 'K'
    mov byte [0xb8000 + 1], 0x07

    ;; Print the Welcome message
    mov esi, WelcomeKernelMessage
    mov edi, 0xb8000 
    call PrintString32


jmp $    ; Infinite loop


PrintString32:
    ; Inputs: ESI = pointer to string, EDI = pointer to video memory
.loop:
    lodsb                   ; Load a byte from [ESI] into AL, increment ESI
    test al, al             ; Check if AL is 0 (null terminator)
    jz .done                ; If null, string has ended
    mov [edi], al           ; Store the ASCII value in video memory
    inc edi                 ; Move to the attribute byte
    mov al, [attr]          ; Load the attribute
    mov [edi], al           ; Store the attribute
    inc edi                 ; Move to the next character slot
    jmp .loop               ; Repeat the process
.done:
    ret 


WelcomeKernelMessage: db "Welcome to the Kernel", 0

attr db 0x07

times 1024 - ($ - $$) db 0
