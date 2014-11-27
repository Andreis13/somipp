
[bits 16]
[org 0x7C00]

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



sleep_1_sec:
  mov  cx, 18
  mov  bx, [es:46Ch]
  wait_for_change:
  no_change:
  mov  ax, [es:46Ch]
  cmp  ax, bx
  je   no_change
  mov  bx, ax
  loop wait_for_change
  ret


msg db  "Welcome to My Operating System!", 0
msg2 db  "Rebooting", 0
stack: times 16 db 0


bootloader_start:

mov si, msg
call putStrLn

xor ax, ax
int 16h ; wait for keypress

mov si, msg2
call putStr

; set es segment for sleep proc
mov ax, 0
mov es, ax
call sleep_1_sec
; print dot
mov al, '.'
mov ah, 0Eh
int 10h

call sleep_1_sec
mov al, '.'
mov ah, 0Eh
int 10h

call sleep_1_sec
mov al, '.'
mov ah, 0Eh
int 10h

int 19h ; reboot

; halt
cli
hlt

times 510 - ($-$$) db 0 ; pad with zeros in order to fill the 512 bytes

dw 0AA55h ; bootsector signature
