;********************************************
; A20.inc - A20 line test and enable routines
;********************************************
%ifndef __A20_INC_INCLUDED__
%define __A20_INC_INCLUDED__

bits 16

;--------------------------------------------------
; External dependency: Print (to display error messages)
;--------------------------------------------------

        
;--------------------------------------------------
; Memory: uses ES:DI = 0x0000:0x0500 and DS:SI = 0xFFFF:0x0510 to test wrap
;--------------------------------------------------
GetA20State:
    pushf
    push ds
    push es
    push di
    push si
    cli

    xor ax, ax
    mov es, ax         ; ES = 0
    mov di, 0x0500     ; test address below 1 MiB
    mov ax, 0xFFFF
    mov ds, ax         ; DS = 0xFFFF
    mov si, 0x0510     ; test address above 1 MiB

    mov al, [es:di]    ; save original bytes
    push ax
    mov al, [ds:si]
    push ax

    mov al, 0x00
    mov [es:di], al
    mov al, 0xFF
    mov [ds:si], al
    cmp byte [es:di], 0xFF

    pop ax
    mov [ds:si], al
    pop ax
    mov [es:di], al

    mov ax, 0
    je .state_exit     ; if zero-flag set, wrap occurred
    mov ax, 1          ; non-zero means A20 enabled
.state_exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

;----------------------------------------------
; Wait helpers for keyboard controller method
;----------------------------------------------
wait_input:
    in  al, 0x64
    test al, 2
    jnz wait_input
    ret

wait_output:
    in  al, 0x64
    test al, 1
    jz  wait_output
    ret

;--------------------------------------------
; Enables A20 line through keyboard controller (fast)
;--------------------------------------------
EnableA20_KKbrd:
    cli
    mov al, 0xDD
    out 0x64, al      ; pulse enable A20
    sti
    ret

;--------------------------------------------
; Enables A20 line through keyboard controller (full)
;--------------------------------------------
EnableA20_KKbrd_Out:
    cli
    pusha
    call wait_input
    mov  al, 0xAD
    out  0x64, al       ; disable keyboard
    call wait_input

    mov  al, 0xD0
    out  0x64, al       ; read output port
    call wait_output
    in   al, 0x60
    push eax            ; save port data
    call wait_input

    mov  al, 0xD1
    out  0x64, al       ; prepare write output port
    call wait_input
    pop  eax
    or   al, 0x02       ; set A20 bit
    out  0x60, al       ; write back
    call wait_input

    mov  al, 0xAE
    out  0x64, al       ; re-enable keyboard
    call wait_input
    popa
    sti
    ret

;--------------------------------------
; Enables A20 line through BIOS
;--------------------------------------
EnableA20_Bios:
    pusha
    mov  ax, 0x2401     ; BIOS A20 service
    int  0x15
    popa
    ret

;-------------------------------------------------
; Enables A20 line through system control port A
;-------------------------------------------------
EnableA20_SysControlA:
    cli
    in   al, 0x92
    or   al, 0x02       ; set A20 enable bit
    out  0x92, al
    sti
    ret

;--------------------------------------------------
; Master A20 enable routine
; Relies on GetA20State to set ZF=1 when enabled
;--------------------------------------------------
EnableA20:
    cli

    call GetA20State
    jnz .a20_done      ; if AX=1 (

    ; 1) Try BIOS method
    call EnableA20_Bios
    call GetA20State
    jnz .a20_done

    ; 2) Try keyboard-controller full method
    call EnableA20_KKbrd_Out
    call GetA20State
    jnz .a20_done

    ; 3) Try fast keyboard pulse
    call EnableA20_KKbrd
    call GetA20State
    jnz .a20_done

    ; 4) Try fast port method
    call EnableA20_SysControlA
    call GetA20State
    call GetA20State
    jnz .a20_done

    ; All methods failed
    mov si, msg_A20_failed
    call Puts16
    hlt

.a20_done:
    sti
    mov si, msg_success
    call Puts16
    ret

;--------------------------------------
; Error message if A20 enable fails
;--------------------------------------
msg_A20_failed: db 'Error: A20 line enable failed!', 0x0D,0x0A, 0
msg_success : db 'Successfully Enabled A20 Line', 0x0D, 0x0A, 0
%endif ; __A20_INC_INCLUDED__
