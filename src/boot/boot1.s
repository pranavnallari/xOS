org 0x7C00
bits 16



jmp short start
nop

bpbOEM:                         db 'MSDOS4.1'     
bpbBytesPerSector:              dw 512
bpbSectorsPerCluster:           db 1
bpbReservedSectors:             dw 1
bpbFatCount:                    db 2
bpbRootEntries:                 dw 0E0h
bpbTotalSectors:                dw 2880              
bpbMediaDescriptor:             db 0F0h            
bpbSectorsPerFAT:               dw 9                
bpbSectorsPerTrack:             dw 18
bpbNumberOfHeads:               dw 2
bpbHiddenSectors:               dd 0
bpbLargeSectors:                dd 0

; extended boot record
bsDriveNumber:                  db 0                  
                                db 0                  
bsSignature:                    db 29h
bsVolumeID:                     db 12h, 34h, 56h, 78h  
bsVolumeLabel:                  db 'XOS        '   
bsSystemID:                     db 'FAT12   '        



start:
    mov ax, 0          
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00       


    push es
    push word .after
    retf

.after:


    mov [bsDriveNumber], dl


    mov si, msg_loading
    call Print


    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    and cl, 0x3F                       
    xor ch, ch
    mov [bpbSectorsPerTrack], cx   

    inc dh
    mov [bpbNumberOfHeads], dh                 

    mov ax, [bpbSectorsPerFAT]
    mov bl, [bpbFatCount]
    xor bh, bh
    mul bx                              
    add ax, [bpbReservedSectors]      
    push ax

    mov ax, [bpbRootEntries]
    shl ax, 5                           
    xor dx, dx                          
    div word [bpbBytesPerSector]     

    test dx, dx                       
    jz .load_root
    inc ax                           
                                      
.load_root:
    mov cl, al                         
    pop ax                            
    mov dl, [bsDriveNumber]       
    mov bx, buffer                     
    call ReadDisk

    xor bx, bx
    mov di, buffer

.search_root_for_stage2:
    mov si, file_kernel_bin
    mov cx, 11                       
    push di
    repe cmpsb
    pop di
    je .found_stage2

    add di, 32
    inc bx
    cmp bx, [bpbRootEntries]
    jl .search_root_for_stage2

    jmp kernel_not_found_error

.found_stage2:

    mov ax, [di + 26]                
    mov [cluster], ax

    mov ax, [bpbReservedSectors]
    mov bx, buffer
    mov cl, [bpbSectorsPerFAT]
    mov dl, [bsDriveNumber]
    call ReadDisk

    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
    mov ax, [cluster]
    

    add ax, 31                      
                                     
    mov cl, 1
    mov dl, [bsDriveNumber]
    call ReadDisk

    add bx, [bpbBytesPerSector]

    mov ax, [cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                       

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                  

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                 
    jae .read_finish

    mov [cluster], ax
    jmp .load_stage2_loop

.read_finish:
    mov dl, [bsDriveNumber]      

    mov ax, STAGE2_LOAD_SEGMENT      
    mov ds, ax
    mov es, ax

    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot           

    cli                               
    hlt




floppy_error:
    mov si, msg_read_failed
    call Print
    jmp wait_key_and_reboot

kernel_not_found_error:
    mov si, msg_kernel_not_found
    call Print
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                   
    jmp 0FFFFh:0               

.halt:
    cli                         
    hlt



Print:
    push si
    push ax
    push bx

.loop:
    lodsb              
    or al, al          
    jz .done

    mov ah, 0x0E     
    mov bh, 0         
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret



lba_to_chs:

    push ax
    push dx

    xor dx, dx                          
    div word [bpbSectorsPerTrack]    
                                    

    inc dx                           
    mov cx, dx                        

    xor dx, dx                      
    div word [bpbNumberOfHeads]               
                                    
    mov dh, dl                     
    mov ch, al                       
    shl ah, 6
    or cl, ah                         

    pop ax
    mov dl, al                      
    pop ax
    ret



ReadDisk:

    push ax                        
    push bx
    push cx
    push dx
    push di

    push cx                          
    call lba_to_chs                 
    pop ax                         
    
    mov ah, 02h
    mov di, 3                       

.retry:
    pusha                        
    stc                             
    int 13h                           
    jnc .done                          

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             
    ret


disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_loading:            db 'Loading...', 0x0D, 0x0A, 0
msg_read_failed:        db 'Read from disk failed!', 0x0D, 0x0A, 0
msg_kernel_not_found:   db 'STAGE2.BIN file not found!', 0x0D, 0x0A, 0
file_kernel_bin:        db 'STAGE2  BIN'
cluster:         dw 0

STAGE2_LOAD_SEGMENT     equ 0x0050
STAGE2_LOAD_OFFSET      equ 0


times 510-($-$$) db 0
dw 0AA55h

buffer: