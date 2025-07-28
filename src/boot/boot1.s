; boot1.s - Boot sector for a floppy disk in 16-bit real mode
; This code is a simple bootloader that reads the second sector of the floppy disk
; and jumps to it for execution. It also includes a BIOS Parameter Block (BPB)
; for compatibility with DOS 4.0.

[org 0x7C00]      ; Set origin for addressing
[bits 16]         ; 16-bit real mode

start: jmp main

; BIOS Parameter BLOCK (DOS 4.0)

OEMLabel:                   db 'MSDOS4.0'       ; OEM Name (8 bytes)

bpbBytesPerSector:          dw 512              ; 0x200 bytes per sector
bpbSectorsPerCluster:       db 1                ; 1 sector per cluster
bpbReservedSectors:         dw 1                ; 1 reserved sector (boot sector)
bpbNumberOfFATs:            db 2                ; 2 FAT copies
bpbRootEntries:             dw 224              ; Max root directory entries
bpbTotalSectors16:          dw 2880             ; 1.44MB floppy (2880 sectors)
bpbMediaDescriptor:         db 0xF0             ; Standard floppy descriptor
bpbSectorsPerFAT:           dw 9                ; 9 sectors per FAT
bpbSectorsPerTrack:         dw 18               ; 18 sectors per track
bpbNumberOfHeads:           dw 2                ; 2 heads (double-sided)
bpbHiddenSectors:           dd 0                ; No hidden sectors
bpbTotalSectors32:          dd 0                ; Not used for FAT12
bsDriveNumber:              db 0x00             ; Floppy disk A:
bsUnused:                   db 0x00             ; Reserved
bsExtBootSignature:         db 0x29             ; Indicates extended boot record
bsSerialNumber:             dd 0xA0A1A2A3       ; Volume ID (used by OS)
bsVolumeLabel:              db "MOS FLOPPY "    ; Must be 11 bytes (pad with spaces)
bsFileSystem:               db "FAT12   "       ; Must be 8 bytes (pad with spaces)


Print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 10h
    jmp Print

.done:
    ret


main:

.Reset:
    mov     ah, 0         ; Function to reset the disk controller
    mov     dl, 0         ; Select drive A: (Floppy disk)
    int     0x13          ; Reset the disk controller
    jc      .Reset

    mov		ax, 0x1000				; we are going to read sector into address 0x1000:0
	mov		es, ax
	xor		bx, bx
 
	mov		ah, 0x02				; read floppy sector function
	mov		al, 1					; read 1 sector
	mov		ch, 1					; we are reading the second sector past us, so its still on track 1
	mov		cl, 2					; sector to read (The second sector)
	mov		dh, 0					; head number
	mov		dl, 0					; drive number. Remember Drive 0 is floppy drive.
	int		0x13					; call BIOS - Read the sector
	
    mov si, boot1_msg          ; Load the message address
    call Print

	jmp		0x1000:0x0				; jump to execute the sector!

boot1_msg: db 'Completed BOOT1.s', 0x0D, 0x0A, 0

; Boot signature (required by BIOS)
times 510-($-$$) db 0
dw 0xAA55

;  Boot sector code ends here, next code will be loaded at 0x1000:0
