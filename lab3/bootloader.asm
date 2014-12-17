;****************;
;** BOOTLOADER **;
;****************;

[bits 16]
mov ax, 07C0h
mov ds, ax
mov es, ax

jmp bootloader_start

putStr:
  lodsb           ; ds:si -> al
  or  al, al      ; al=current character
  jz  exit_putStr ; exit if null terminator found
  mov ah, 0Eh     ; print char in al in teletype mode
  int 10h
  jmp putStr
exit_putStr:
  ret


newLine:
  mov al, 0Dh
  mov ah, 0Eh
  int 10h
  mov al, 0Ah
  int 10h
  ret


putStrLn:
  call putStr
  call newLine
  ret



msg db  "Press any key to load kernel", 0
msg2 db  "Error!", 0
cpuid_buffer times 14 db 0
stack: times 16 db 0


bootloader_start:

mov si, msg
call putStrLn

xor ax, ax
int 16h ; wait for keypress

reset_floppy:
  mov ah, 0        ; reset floppy disk function
  mov dl, 0        ; drive 0 is floppy drive
  int 13h          ; call BIOS
  jc reset_floppy  ; retry if an error occured

; set destination segment
mov ax, 07E0h
mov es, ax
xor bx, bx

read_from_floppy:
  mov ah, 2 ; read sectors
  mov al, 5 ; number of sectors to read
  mov ch, 0 ; track number
  mov cl, 2 ; sector number (kernel is in the second sector)
  mov dh, 0 ; head number
  mov dl, 0 ; drive number
  int 13h   ; call BIOS
  jc read_from_floppy        ; Error, so try again


; check data integrity
mov al, byte [es:0h]
cmp al, 0B8h
je kernel_jump


; print error message and halt system if data integrity check failed
mov si, msg2
call putStrLn

cli
hlt

kernel_jump:
  jmp 7E0h:0h ; jump to kernel


times 510 - ($-$$) db 0 ; pad with zeros in order to fill the 512 bytes

dw 0AA55h

