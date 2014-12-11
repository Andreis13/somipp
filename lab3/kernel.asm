;************;
;** KERNEL **;
;************;

[bits 16]
mov ax, 07E0h
mov ds, ax
mov es, ax
add ax, 40h
mov ss, ax
mov ax, 62
mov sp, ax



jmp kernel_start

putStr:
  cld
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
  mov cx, 32
  xor eax, eax
  cld

  .clear_buffer:
    stosd
  loop .clear_buffer

  mov di, input_buffer
  get_char:
  xor ax, ax
  int 16h
  cmp al, 0Dh ; check carriage return
  je exit_getStrLn
  cmp al, 08h ; check backspace
  je handle_backspace
  cmp al, 20h ; check lower bound of printable characters
  jl get_char
  cmp al, 7Eh ; check higher bound of printable characters
  jg get_char
  stosb
  mov ah, 0Eh ; echo character
  int 10h
  jmp get_char

  handle_backspace:
    cmp di, input_buffer
    je get_char
    mov al, 08h ; echo backspace
    int 10h
    dec di
    mov byte[di], 0 ; clear printed character
    mov al, ' '
    int 10h
    mov al, 08h ; echo backspace
    int 10h
    jmp get_char

  exit_getStrLn:
    mov al, 0
    stosb
    call newLine
    ret


printAX:
  push bx

  mov bx, ax
  shr ax, 12
  add al, 30h
  mov ah, 0Eh
  int 10h

  mov ax, bx
  shr ax, 8
  and al, 0Fh
  add al, 30h
  mov ah, 0Eh
  int 10h

  mov ax, bx
  shr al, 4
  add al, 30h
  mov ah, 0Eh
  int 10h

  mov ax, bx
  and al, 0Fh
  add al, 30h
  mov ah, 0Eh
  int 10h

  pop bx
  ret


cmd_echo:
  mov si, input_buffer+4
  .check_space:
  inc si
  cmp byte [si], ' '
  je .check_space
  call putStrLn
  ret

cmd_restart:
  int 19h
  ret

cmd_reverse:
  ; push bx
  mov si, input_buffer + 7
  .find_start:
  inc si
  cmp byte [si], ' '
  je .find_start
  cmp byte [si], 0
  je exit_cmd_reverse
  mov al, byte [si]
  mov ah, 0Eh
  int 10h

  ; mov bx, si
  ; .find_end:
  ; inc si
  ; cmp byte [si], 0
  ; jne .find_end
  ; dec si

  ; mov ah, 0Eh
  ; std
  ; .print_char:
  ; lodsb
  ; int 10h
  ; cmp si, bx
  ; je exit_cmd_reverse
  ; jmp .print_char

  exit_cmd_reverse:
  ; pop bx
  cld
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

cmd_hex2dec:
  ret

cmd_dec2hex:
  ret

cmd_eval:
  ret

test_stack:
  mov ax, sp
  call printAX
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
  cmp byte [input_buffer], 0
  je read_command

  ; TODO handle leading spaces
  mov bx, commands
  mov cx, 4         ; set number of commands
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
    cmp byte [si], ' '
    jne no_match
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
  db "reverse    ", 0
  dw cmd_reverse
  db "dec2hex    ", 0
  dw cmd_dec2hex
  db "hex2dec    ", 0
  dw cmd_hex2dec
  db "eval       ", 0
  dw cmd_eval



times 1024 - ($-$$) db 0 ; pad with zeros in order to fill the 1024 bytes

stack:
  times 64 db 0

times 1536 - ($-$$) db 0


