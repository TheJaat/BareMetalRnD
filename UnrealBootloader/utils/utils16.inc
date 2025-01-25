%ifndef UTILS16_INC
%define UTILS16_INC

BITS 16

;; **************************************************
;; Reset Cursor:
;; Resets the cursor to the default position
;; top left corner.
;;
;; IN -
;;    Nothing
;; OUT -
;;     Nothing
;; --------------------------------------------------
ResetCursor:
    pusha
    mov ah, 0x02    ; Set Cursor position
    xor bh, bh      ; Page number (0 for default)
    xor dh, dh      ; Row 0
    xor dl, dl      ; Column 0
    int 0x10        ; Call BIOS interrupt
    popa
ret


;; **************************************************
;; ClearScreen:
;; Clear the screen by using scroll up interrupt call
;; and resets the cursor to the default position
;; top left corner.
;;
;; IN -
;;    Nothing
;; OUT -
;;     Nothing
;; --------------------------------------------------
ClearScreen:
    pusha
    mov ah, 0x06    ; Function: Scroll up
    mov al, 0       ; Clear entire screen (0 rows to scroll means all)
    mov bh, 0x07    ; Attribute: Light gray on black
    mov cx, 0x0000  ; Top-left corner (row 0, col 0)
    mov dx, 0x184f  ; Bottom-right corner (row 24, col 79)
    int 0x10        
    
    call ResetCursor ; Reset the cursor to the default top-left corner
    popa
ret


;; **************************************************
;; Newline16:
;; Moves the cursor to the beginning of the next line.
;;
;; IN -
;;    Nothing
;; OUT -
;;     Nothing
;; State -
;;     Saved
;; --------------------------------------------------
Newline16:
    pusha                ; Save all registers
    mov ah, 0x0e         ; BIOS teletype function
    mov al, 0x0D         ; Carriage Return
    int 0x10             ; Print it
    mov al, 0x0A         ; Line Feed
    int 0x10             ; Print it
    popa                 ; Restore all registers
ret


;; **************************************************
;; PrintString16:
;; Print the string using interrupt
;;
;; IN -
;;    Nothing
;; OUT -
;;     Nothing
;; State -
;;     Saved
;; --------------------------------------------------
PrintString16:
    pusha                ; Save all registers on the stack to preserve their values
    .loopy:              ; Start of the loop
        lodsb            ; Load the next byte from the string pointed to by DS:SI into AL and increment SI
        or al, al        ; Check if AL is zero (end of string, null terminator)
        jz .done         ; If AL is zero, jump to the .done label to finish
        mov ah, 0x0e     ; Set up the BIOS teletype function (INT 0x10, AH=0x0E)
        mov bx, 7        ; Set text attribute (e.g., white text on black background)
        int 0x10         ; Call the BIOS interrupt to display the character in AL
        jmp .loopy       ; Repeat the loop for the next character
    .done:
        call Newline16   ; Call the Newline16 procedure to add a newline after the string
    popa                 ; Restore all registers from the stack
ret                      ; Return to the caller



%endif ;; UTILS16_INC
