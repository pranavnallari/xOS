; stage2.s

org 0x500    ; Correct base address where stage2 is loaded (0x50:0x0)

[bits 16]    ; 16-bit real mode

start: jmp main

%include "stdio.inc"
%include "gdt.inc"
%include "a20.inc"

;*************************************************;
; Second Stage Loader Entry Point
;************************************************;

main:
    ; Clear interrupts first
    cli

    ; CRITICAL FIX: Set up proper REAL MODE segments
    ; Original bug: was setting DS=0x10, ES=0x10 (protected mode selectors!)
    xor ax, ax
    mov ds, ax      ; Set DS to 0 (real mode segment)
    mov es, ax      ; Set ES to 0 (real mode segment)
    
    ; CRITICAL FIX: Set up stack in safe location
    ; Original bug: stack at 0x9000 could conflict with loaded code
    mov ax, 0x8000  ; Use 0x8000 instead of 0x9000  
    mov ss, ax
    mov sp, 0xFFFF
    
    ; Re-enable interrupts for BIOS calls
    sti

    ; Print boot message using 16-bit function
    mov si, boot2_msg
    call Puts16

    ; Enable A20 line (allows access to memory above 1MB)
    call EnableA20
    
    ; Load Global Descriptor Table
    lgdt [toc]
    
    ; Enter protected mode
    cli                     ; Disable interrupts before mode switch
    mov eax, cr0
    or al, 1               ; Set Protection Enable bit
    mov cr0, eax

    ; CRITICAL: Far jump to flush prefetch queue and set CS register
    ; This switches from real mode to protected mode addressing
    jmp 08h:Stage3         ; Jump to code selector 0x08

[bits 32]
; Now we're in 32-bit protected mode

Stage3:
    ; CRITICAL FIX: Set up ALL segment registers with data selector
    ; Original bug: segment registers not initialized after mode switch
    mov ax, 10h        ; Data segment selector (offset 0x10 in GDT)
    mov ds, ax         ; All these must be set to valid selectors
    mov es, ax         ; in protected mode, or system will crash
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up new 32-bit stack
    mov esp, 0x90000   ; 32-bit stack pointer
    
    ; Call main 32-bit function
    call BEGIN_PM
    
    ; Halt if we return (should never happen)
    cli
    hlt

BEGIN_PM:
    ; Clear screen using 32-bit function
    call ClrScr32
    
    ; Print success message to show protected mode is working
    mov ebx, success_msg
    call Puts32
    
    ; Success! Infinite loop to keep system running
.hang:
    cli
    hlt
    jmp .hang

;*************************************************;
; Data Section  
;************************************************;

boot2_msg:      db 'Starting Stage 2....', 0x0D, 0x0A, 0
success_msg:    db 'Protected mode activated successfully!', 0x0D, 0x0A, 0
