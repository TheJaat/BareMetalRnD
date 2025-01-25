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
    mov ah, 0x02    ; Set Cursor position
    xor bh, bh      ; Page number (0 for default)
    xor dh, dh      ; Row 0
    xor dl, dl      ; Column 0
    int 0x10        ; Call BIOS interrupt
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
;; ------------------------------------------
ClearScreen:
    mov ah, 0x06    ; Function: Scroll up
    mov al, 0       ; Clear entire screen (0 rows to scroll means all)
    mov bh, 0x07    ; Attribute: Light gray on black
    mov cx, 0x0000  ; Top-left corner (row 0, col 0)
    mov dx, 0x184f  ; Bottom-right corner (row 24, col 79)
    int 0x10        
    
    call ResetCursor ; Reset the cursor to the default top-left corner
ret


%endif ;; UTILS16_INC
