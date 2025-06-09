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

    ; Load 10 sectors from floppy into 0x1000:0x0000
    mov bx, 0x1000        ; ES = 0x1000
    mov es, bx
    xor bx, bx            ; BX = 0
    mov ah, 0x02          ; BIOS read sectors
    mov al, 10            ; read 10 sectors
    mov ch, 0             ; cylinder
    mov cl, 2             ; sector 2 (bootloader is sector 1)
    mov dh, 0             ; head
    mov dl, 0             ; drive 0 (floppy)
    int 0x13
    jc disk_error

    call load_gdt ; Load the GDT Table with the starting address of the Table

    mov eax, cr0
    or al, 1    ; set Protection Enable (PE) bit in CR0 (Control register 0)
    mov cr0, eax
    ; After enabling protected mode, the CPU will still interpret instructions as 16-bit until the Code Segment (CS)
    ; register is reloaded with a 32-bit descriptor.
    ; Far jump to flush pipeline and enter protected mode
    jmp 08h:protected_mode_entry   ;  0x08 is the offset in the GDT of the 32-bit code segment


disk_error: ; Hang forever if disk read failed
    cli
    hlt
    jmp $

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
    mov esp, 0x90000
    ; This sets up all memory acceses to use the 4GB space we defined in the GDT.
 
    jmp dword 0x10000

    
times 510 - ($ - $$) db 0	;fill the rest of the sector with 0's
dw 0xAA55
