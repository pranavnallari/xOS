%ifndef __STDIO_INC_INCLUDED__
%define __STDIO_INC_INCLUDED__



bits	16
 
Puts16:
		pusha				; save registers
.Loop1:
		lodsb				; load next byte from string from SI to AL
		or	al, al			; Does AL=0?
		jz	Puts16Done		; Yep, null terminator found-bail out
		mov	ah, 0eh			; Nope-Print the character
		int	10h			; invoke BIOS
		jmp	.Loop1			; Repeat until null terminator found
Puts16Done:
		popa				; restore registers
		ret				; we are done, so return
 

bits 32

%define VMEM	0xB8000
%define COLS	80
%define LINES	25
%define CHAR_ATTR	63

_cur_x	db 0
_cur_y	db 0


Putch32:
	pusha
	mov edi, VMEM

	; get current position
	xor eax, eax

	mov ecx, COLS*2
	mov al, byte [_cur_y]

	mul ecx
	push eax

	mov al, byte [_cur_x]
	mov cl, 2
	mul cl

	pop ecx
	add eax, ecx

	xor ecx, ecx
	add edi, eax

	cmp bl, 0x0A
	je .Row

	mov dl, bl
	mov dh, CHAR_ATTR
	mov word [edi], dx

	inc byte [_cur_x]
	cmp byte [_cur_x], COLS
	je .Row
	jmp .done

.Row:
	mov byte [_cur_x], 0
	inc byte [_cur_y]

.done:
	popa
	ret

Puts32:
	pusha
	push ebx
	pop edi

.loop:
	mov bl, byte [edi]
	cmp bl, 0
	je .done

	call Putch32

	inc edi
	jmp .loop

.done:
	mov bh, byte [_cur_y]
	mov bl, byte [_cur_x]
	call MovCur

	popa
	ret


bits 32

MovCur:
	pusha

	xor eax, eax
	mov ecx, COLS
	mov al, bh
	mul ecx
	add al, bl
	mov ebx, eax
	mov al, 0x0f
	mov	dx, 0x03D4
	out	dx, al

	mov	al, bl
	mov	dx, 0x03D5
	out	dx, al	
	xor	eax, eax

	mov	al, 0x0e
	mov	dx, 0x03D4
	out	dx, al

	mov	al, bh
	mov	dx, 0x03D5
	out	dx, al			; high byte

	popa
	ret

bits 32

ClrScr32:

	pusha
	cld
	mov	edi, VMEM
	mov	cx, 2000
	mov	ah, CHAR_ATTR
	mov	al, ' '	
	rep	stosw

	mov	byte [_cur_x], 0
	mov	byte [_cur_y], 0
	popa
	ret

	
bits 32

GotoXY:
	pusha
	mov	[_cur_x], al		; just set the current position
	mov	[_cur_y], ah
	popa
	ret

%endif