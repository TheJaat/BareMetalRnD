format pe64 efi
entry main

section '.text'

main:

    mov rcx, [rdx + 64]
    mov rax, [rcx + 8]
    mov rdx, string
    sub rsp, 32
    call rax
    add rsp, 32
    ret


section '.data'

string du 'Hello, World!', 0xD, 0xA, 0
