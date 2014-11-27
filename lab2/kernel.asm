;************;
;** KERNEL **;
;************;

[bits 16]
mov ax, 07E0h
mov ds, ax
mov es, ax

jmp kernel_start

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

;** DATA **

k_msg db "Kernel loaded!", 0



kernel_start:

mov si, k_msg
call putStrLn

cli
hlt

times 512 - ($-$$) db 0 ; pad with zeros in order to fill the 512 bytes


