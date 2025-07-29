; stage2.s - Second stage bootloader

[org 0x0]      ; Set origin for addressing
[bits 16]         ; 16-bit real mode

start: jmp main

Print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 10h
    jmp Print
	
.done:
    ret


;*************************************************;
;	Second Stage Loader Entry Point
;************************************************;
 
main:
		
		cli		; clear interrupts
		push	cs	; Insure DS=CS
		pop	ds
		mov si, boot2_msg
		call Print

		jmp $

 
;*************************************************;
;	Data Section
;************************************************;
 
boot2_msg: db 'Starting Stage 2....', 0x0D, 0x0A, 0

times 512-($-$$) db 0