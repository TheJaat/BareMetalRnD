BITS 16

ORG 0x7c00

jmp short start

sectors: dw 800

start:
    cli
    cld
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00
    call enableA20
    lgdt [ss:gdt]
    mov eax, cr0
    or al, 0x1
    mov cr0, eax
    jmp dword 0x8: unreal32

unreal32:
    mov bx, 0x10
    mov ds, bx
    mov es, bx
    mov ss, bx
    and al, 0xfe
    mov cr0, eax
    jmp 0x7c0:unreal-0x7c00

unreal:
    xor ax, ax
    mov es, ax
    mov ds, ax
    mov ss, ax

    xor dx, dx
    mov bx, 0x2
    mov cx, 1
    mov edi, 0x7e00
    sti
;;    call load_floppy


;; temp start

; Read a single sector from the disk (floppy drive, sector 1)
mov ah, 0x02            ; Function: Read Sectors
mov al, 0x01            ; Number of sectors to read (1)
mov ch, 0x00            ; Cylinder (track) number (0)
mov cl, 0x02            ; Sector number (1, starts at 1)
mov dh, 0x00            ; Head number (0)
mov dl, 0x80            ; Drive number (0 = floppy)
mov bx, 0x7e00          ; Offset for the buffer (0x7C00)
;mov es, 0x0000          ; Segment for the buffer
int 0x13                ; BIOS interrupt for disk services

jc disk_error           ; Check for errors (CF set), jump if error
jmp done                ; Success, continue execution

disk_error:
mov ah, 0x0E            ; BIOS function to print a character
mov al, 'E'             ; Print 'E' on error
int 0x10                ; Call BIOS to display character
hlt                    ; Halt execution

done:
; Continue with the program

;; Read in the rest of the disk
mov edi, 0x100000
mov bx, 0x3
mov cx, [sectors]
xor dx, dx
sti
mov si, loadmsg
call print
dec cx



;; temp end

;    mov edi, 0x100000
;    mov bx, 0x3
;    mov cx, [sectors]
;    xor dx, dx
;    sti
    mov si, loadmsg
    call print
;    dec cx
;    call load_floppy


    mov si, okMsg
    call print
    cli

infinite:
jmp infinite


mov ebx, [dword 0x100074]
add ebx, 0x101000
mov al, 0xcf
mov [ds:gdt + 14], al
mov [ds:gdt + 22], al
lgdt [ds:gdt]

mov eax, 1
mov cr0, eax
jmp dword 0x8:code32

code32:
BITS 32
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x10000
    mov esp, ebp


hlt





BITS 16
; read sectors into memory
; IN: bx = sector # to start with: should be 2 as sector 1 (bootsector) was read by BIOS
;     cx = # of sectors to read
;     edi = buffer
load_floppy:
	push	bx
	push	cx
tryagain:
	mov		al,0x13          ; read a maximum of 18 sectors
	sub		al,bl            ;   substract first sector (to prevent wrap-around ???)

	xor		ah,ah            ; TK: don't read more then required, VMWare doesn't like that
	cmp		ax,cx
	jl		shorten
	mov		ax,cx
shorten:

	mov		cx,bx            ;   -> sector/cylinder # to read from
	mov		bx,0x8000        ; buffer address
	mov		ah,0x2           ; command 'read sectors'
	push	ax
	int		0x13             ;   call BIOS
	pop		ax               ; TK: should return number of transferred sectors in al
	                         ; but VMWare 3 clobbers it, so we (re-)load al manually
	jnc		okok             ;   no error -> proceed as usual
	dec		byte [retrycnt]
	jz		fail
	xor		ah,ah			 ; reset disk controller
	int		0x13
	jmp		tryagain		 ; retry
okok:
	mov		byte [retrycnt], 3	; reload retrycnt
	mov		si,dot
	call	print
	mov		esi,0x8000       ; source
	xor		ecx,ecx
	mov		cl,al            ; copy # of read sectors (al)
	shl		cx,0x7           ;   of size 128*4 bytes
	rep	a32 movsd        ;   to destination (edi) setup before func3 was called
	pop		cx
	pop		bx
	xor		dh,0x1           ; read: next head
	jnz		bar6
	inc		bh               ; read: next cylinder
bar6:
	mov		bl,0x1           ; read: sector 1
	xor		ah,ah
	sub		cx,ax            ; substract # of read sectors
	jg		load_floppy      ;   sectors left to read ?
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
    popa
ret



; print errormsg, wait for keypress and reboot
fail:
	mov		si,errormsg
	call	print
	xor		ax, ax
	int		0x16
	int		0x19

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


loadmsg		db	"Loading",0
errormsg	db	0x0a,0x0d,"Error reading disk.",0x0a,0x0d,0
okMsg		db	"OK",0x0a,0x0d,0
dot			db	".",0

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

retrycnt	db 3

times 510-($-$$) db 0  ; filler for boot sector
dw 0xaa55            ; magic number for boot sector


times 1024-($-$$) db 0  ; filler for second sector of the loader

