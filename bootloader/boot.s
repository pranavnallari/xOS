; bootloader/boot.s

[bits 16]       ; 16 bit Real Mode
[org 0x7c00]    ; Start of the boot sector address for bootloader

; before protected mode
start:
    cli     ; disable interrupts
    xor ax, ax  ; reset these registers
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00  ; set default SP location

    call load_gdt ; Load the GDT Table with the starting address of the Table

    mov eax, cr0
    or al, 1    ; set Protection Enable (PE) bit in CR0 (Control register 0)
    mov cr0, eax
    ; After enabling protected mode, the CPU will still interpret instructions as 16-bit until the Code Segment (CS)
    ; register is reloaded with a 32-bit descriptor.
    ; Far jump to flush pipeline and enter protected mode
    jmp 08h:protected_mode_entry   ;  0x08 is the offset in the GDT of the 32-bit code segment

; ------------------------------------------------------------------------------
; Include GDT setup
%include "gdt.s"

; -----------------------------------------------------------------------------
; start of 32-bit protected mode
[bits 32]
protected_mode_entry:
    ; Load all the registers
    mov ax, 0x10   ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; This sets up all memory acceses to use the 4GB space we defined in the GDT.

    ; Start of Printing our String
    mov esi, msg
    mov edi, 0xB8000

.next_char:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0F      ; Light gray on black
    stosw
    jmp .next_char

.halt:
    cli
    hlt


msg db "Hello from Protected Mode!", 0Ah, 0
times 510 - ($ - $$) db 0	;fill the rest of the sector with 0's
dw 0xAA55
