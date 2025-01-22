BITS 16

ORG 0x7c00

jmp short start


start:
    ;; Load the disk number in variable,
    ;; which we get in the dl register
    mov [boot_disk_number], dl


    cli
    cld

    ;; Set up segment registers
    xor ax, ax
    mov ss, ax
    mov ds, ax

    ;; Set up the stack
    mov sp, 0x7c00

    ;; Enable the A20 line
    call enableA20

    ;; Load the 32-bit global descriptor table
    lgdt [ss:gdt]

    ;; Enter protection bit for protected mode
    mov eax, cr0
    or al, 0x1
    mov cr0, eax

    ;; Jump to 32-bit land
    jmp dword 0x8: unreal32

unreal32:
    ;; Set up segment registers
    mov bx, 0x10
    mov ds, bx
    mov es, bx
    mov ss, bx

    ;; Disable protection bit, to jump back for the unreal mode
    and al, 0xfe
    mov cr0, eax

    ;; Jump to unreal mode
    jmp 0x7c0:unreal-0x7c00

;; Unreal mode
unreal:
    ;; Set up segment registers
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax

    ;; Print the stage 1 welcome message
    mov si, stage1WelcomeMsg
    call print

    ;; Load the second sector for the stage1
    mov ah, 0x02            ; BIOS disk read funtion
    mov al, 1               ; Numbers of sector to reads
    mov ch, 0               ; Cylinder 0
    mov cl, 2               ; Sector number to start reading from
                            ; (1-based indexed)
    mov dh, 0               ; Head 0
    mov dl, [boot_disk_number] ; Disk number (HDD = 0x80, Floppy = 0x00)
    mov bx, 0x7e00          ; Read at
    int 0x13                ; Disk Read function
    jc diskReadFailure      ; If carry flag is set means failure

    ;; Load the second stage to 0x100000
    mov ax, 0x1000          ; Load segment address 0x1000 (for 0x100000)
    mov es, ax              ; Set ES to 0x1000
    mov ah, 0x02            ; BIOS disk read function
    mov al, 2               ; Number of sectors to read
    mov ch, 0               ; Cylinder 0
    mov cl, 3               ; Sector number (1-based indexed)
    mov dh, 0               ; Head 0
    mov dl, [boot_disk_number] ; Drive number (HDD = 0x80, Floppy = 0x00)
    mov bx, 0x0000          ; Offset 0x0000
                            ; Read at [es:offset]
    int 0x13                ; BIOS call to read sector
    jc diskReadFailure      ; Check for errors, if carry flag is set, means failure


    ; Jump to stage 2
    jmp 0x1000:0x0000       ; Far jump to 0x100000

; Unreal Mode allows access to this area, but we must set up registers carefully
push 0x1000             ; Push the high 16 bits (segment base) of 0x100000
push 0x0000             ; Push the offset within that segment (0x0)
retf 
jmp $


BITS 16

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


;; print error messsage, wait for keypress and reboot
diskReadFailure:
    mov si, diskReadErrorMsg
    call print
    xor ax, ax
    int 0x16
    int 0x19
jmp $


; Enable the A20 gate
; enables the a20 gate
;   the usual keyboard-enable-a20-gate-stuff
enableA20:
	call	_a20_loop
	jnz		_enable_a20_done
	mov		al,0xd1
	out		0x64,al
	call	_a20_loop
	jnz		_enable_a20_done
	mov		al,0xdf
	out		0x60,al
_a20_loop:
	mov		ecx,0x20000
_loop2:
	jmp		short _c
_c:
	in		al,0x64
	test	al,0x2
	loopne	_loop2
_enable_a20_done:
	ret


;; Data
stage1WelcomeMsg: db "Welcome to Stage1", 0
diskReadErrorMsg: db "Error Reading Disk", 0
boot_disk_number: db 0

gdt:
    ; the first entry serves 2 purposes: as the GDT header and as the first descriptor
    ; note that the first descriptor (descriptor 0) is always a NULL-descriptor
    db 0xFF        ; full size of GDT used
    db 0xff        ;   which means 8192 descriptors * 8 bytes = 2^16 bytes
    dw gdt         ;   address of GDT (dword)
    dd 0
    ; descriptor 1:
    dd 0x0000ffff  ; base - limit: 0 - 0xfffff * 4K
    dd 0x008f9a00  ; type: 16 bit, exec-only conforming, <present>, privilege 0
    ; descriptor 2:
    dd 0x0000ffff  ; base - limit: 0 - 0xfffff * 4K
    dd 0x008f9200  ; type: 16 bit, data read/write, <present>, privilege 0

times 510-($-$$) db 0  ; filler for boot sector (Padding)
dw 0xaa55            ; magic number for boot sector

times 1024 - ($ - $$) db 0
