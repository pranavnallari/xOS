%ifndef __GDT_INC_INCLUDED__
%define __GDT_INC_INCLUDED__

bits 16


;*******************************************
; Global Descriptor Table (GDT)
;*******************************************

gdt_data:
    dq 0              ; null descriptor

gdt_code:
    dw 0FFFFh         ; limit low
    dw 0              ; base low
    db 0              ; base middle
    db 10011010b      ; access
    db 11001111b      ; granularity
    db 0              ; base high

gdt_data_desc:
    dw 0FFFFh
    dw 0
    db 0
    db 10010010b      ; access (data segment)
    db 11001111b
    db 0

end_of_gdt:

toc:
    dw end_of_gdt - gdt_data - 1  ; size
    dd gdt_data                   ; base

%define NULL_DESC 0x00
%define CODE_DESC 0x08
%define DATA_DESC 0x10

%endif
