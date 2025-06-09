; bootloader/gdt.s

load_gdt:
    lgdt [gdt_descriptor]
    ret

gdt_start:
    dq 0x0000000000000000 ; Null descriptor

gdt_code:  ; Code segment: base=0x0, limit=4GB, type=0x9A
    dq 0x00CF9A000000FFFF

gdt_data: ; Data segment: base=0x0, limit=4GB, type=0x92
    dq 0x00CF92000000FFFF

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; Limit
    dd gdt_start                 ; Base


CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start