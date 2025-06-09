[bits 16]

[org 0x7c00]

start:
    mov si, message

.print_char:
    lodsb       ; reads first byte stored in "si" reg into al. then si is incremented
    cmp al, 0   ; checking for null termination
    je halt     ; stop if al == 0
    mov ah, 0x0E; Teletype Mode (Display)
    int 0x10    ; call interrupt
    jmp .print_char ; repeat

halt:
    jmp $

message: db "Hello World!", 0Ah, 00h

times 510 - ($ - $$) db 0	;fill the rest of the sector with 0's
dw 0xAA55
