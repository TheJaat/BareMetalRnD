; UEFI Hello World Bootloader in FASM (PE64 EFI)
; This program prints "Hello, World!" using UEFI's OutputString function.
; The UEFI firmware passes the System Table pointer in RDX.
; We retrieve the Console Output protocol from the System Table,
; then call its OutputString function to display our string.

format pe64 efi             ; Specify the PE32+ (EFI) output format
entry main                  ; Set the entry point to the label "main"

section '.text'             ; Code section

main:
    ; RDX holds the pointer to the EFI System Table.
    ; At offset 64 in the system table, we expect a pointer to the 
    ; Simple Text Output Protocol (ConOut). Load it into RCX.
    mov rcx, [rdx + 64]

    ; The Simple Text Output Protocol structure contains a function pointer
    ; to OutputString at offset 8. Load that pointer into RAX.
    mov rax, [rcx + 8]

    ; Load the address of our string (in the .data section) into RDX.
    mov rdx, string

    ; UEFI functions require proper stack alignment.
    ; Reserve 32 bytes on the stack to satisfy the calling convention.
    sub rsp, 32

    ; Call the OutputString function to print our string.
    call rax

    ; Restore the stack pointer after the call.
    add rsp, 32

    ; Return from main (terminates the application).
    ret

section '.data'             ; Data section

; Define a UTF-16 string "Hello, World!" followed by carriage return (0xD), 
; line feed (0xA), and a null terminator (0).
string du 'Hello, World!', 0xD, 0xA, 0

