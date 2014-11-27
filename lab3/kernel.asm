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

getStrLn:
  mov di, input_buffer
  get_char:
  xor ax, ax
  int 16h
  cmp al, 0Dh ; check carriage return
  je exit_getStrLn
  cmp al, 20h
  jl get_char
  cmp al, 7Eh
  jg get_char
  stosb
  mov ah, 0Eh
  int 10h
  jmp get_char

  exit_getStrLn:
    mov al, 0
    stosb
    call newLine
    ret


;** DATA **

k_msg db "Kernel loaded!", 0
unknown_cmd_msg db "Unknown command!", 0
input_buffer times 128 db 0
cpuid_buffer times 14 db 0

commands:
  db "restart    ", 0
  dw cmd_restart
  db "echo       ", 0
  dw cmd_echo
  db "cpuid      ", 0
  dw cmd_cpuid
  db "beep       ", 0
  dw cmd_beep
  db "shutdown   ", 0
  dw cmd_shutdown


cmd_echo:
  mov si, input_buffer+4
  .check_space
  inc si
  cmp byte [si], ' '
  je .check_space
  call putStrLn
  ret

cmd_restart:
  ret
cmd_shutdown:
  ret
cmd_beep:
  ret
cmd_cpuid:

  xor eax, eax
  cpuid
  mov [cpuid_buffer], ebx
  mov [cpuid_buffer+4], edx
  mov [cpuid_buffer+8], ecx
  mov si, cpuid_buffer
  call putStrLn
  ret

kernel_start:

mov si, k_msg
call putStrLn

read_command:
  mov ah, 0Eh
  mov al, '>'
  int 10h
  mov al, ' '
  int 10h

  call getStrLn

  ; TODO handle leading spaces
  mov bx, commands
  mov cx, 5
  search_command:
  mov si, bx
  mov di, input_buffer
  jmp check_byte
  check_byte:
    cmp byte [di], ' '
    je execute_cmd
    cmp byte [di], 0
    je execute_cmd

    cmpsb
    jne no_match

  jmp check_byte

  execute_cmd:
    call word [bx+12]
    jmp read_command

  no_match:
  add bx, 14
  loop search_command

  unknown_cmd:
  mov si, unknown_cmd_msg
  call putStrLn

jmp read_command


cli
hlt

times 1024 - ($-$$) db 0 ; pad with zeros in order to fill the 512 bytes


