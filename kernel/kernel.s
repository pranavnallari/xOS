; kernel/kernel.s


[bits 32]
org 0x10000

mov esi, message
mov edi, 0xB8000

.next:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0F

    stosw
    jmp .next

.halt:
    cli
    hlt

message db "Hello World!", 0Ah, 0


