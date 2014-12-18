;************;
;** KERNEL **;
;************;

[bits 16]
mov ax, 07E0h
mov ds, ax
mov es, ax
add ax, 80h
mov ss, ax
mov ax, 255
mov sp, ax



jmp kernel_start

put_str:
  cld
  lodsb           ; ds:si -> al
  or  al, al      ; al=current character
  jz  exit_put_str ; exit if null terminator found
  mov ah, 0Eh     ; print char in al in teletype mode
  int 10h
  jmp put_str
exit_put_str:
  ret


new_line:
  mov al, 0Dh
  mov ah, 0Eh
  int 10h
  mov al, 0Ah
  int 10h
  ret


put_str_ln:
  call put_str
  call new_line
  ret

get_str_ln:
  call clear_input_buffer
  cld
  mov di, input_buffer
  get_char:
  xor ax, ax
  int 16h
  cmp al, 0Dh ; check carriage return
  je exit_get_str_ln
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

  exit_get_str_ln:
    mov al, 0
    stosb
    call new_line
    ret


skip_space:
  dec si
  .check_space:
  inc si
  cmp byte[si], ' '
  je .check_space
  ret


strlen:
  push si
  xor cx, cx
  .check_byte:
  cmp byte[si], 0
  je exit_strlen
    inc cx
    inc si
  jmp .check_byte
  exit_strlen:
  pop si
  ret

clear_buffer:
  push cx
  mov cx, ax
  xor eax, eax
  .clear_dd:
    stosb
  loop .clear_dd
  pop cx
  ret

clear_input_buffer:
  push ax
  mov ax, 128
  mov di, input_buffer
  call clear_buffer
  pop ax
  ret

clear_output_buffer:
  push ax
  mov ax, 128
  mov di, output_buffer
  call clear_buffer
  pop ax
  ret

sleep_1_sec:
  push bx
  push cx
  push ax
  mov ax, es
  push ax
  xor ax, ax
  mov es, ax
  mov  bx, [es:46Ch]
  mov  cx, 18
  wait_for_change:
  no_change:
  mov  ax, [es:46Ch]
  cmp  ax, bx
  je   no_change
  mov  bx, ax
  loop wait_for_change
  pop ax
  mov es, ax
  pop ax
  pop cx
  pop bx
  ret

adjust_hex_char:
  cmp al, 9
  jle exit_adjust_hex_char
  add al, 7
  exit_adjust_hex_char:
  add al, 30h
  ret

print_ax_hex:
  push ax
  push bx
  mov bx, ax

  mov ah, 0Eh

  mov al, bh
  shr al, 4
  call adjust_hex_char
  int 10h

  mov al, bh
  and al, 0Fh
  call adjust_hex_char
  int 10h

  mov al, bl
  shr al, 4
  call adjust_hex_char
  int 10h

  mov al, bl
  and al, 0Fh
  call adjust_hex_char
  int 10h

  pop bx
  pop ax
  ret

print_ax_dec:
  push bx
  push dx
  push di
  xor dx, dx
  call clear_output_buffer
  mov di, output_buffer
  mov bx, 10 ; (decimal)
  .make_division:
    div bx
    mov [di], dl
    inc di
    xor dx, dx
    cmp ax, 0
  jne .make_division


  .print_char:
    dec di
    mov al, [di]
    call adjust_hex_char
    mov ah, 0Eh
    int 10h
    cmp di, output_buffer
  jg .print_char

  pop di
  pop dx
  pop bx
  ret

read_ax_hex:
  ret

reat_ax_dec:
  ret

ascii2dec:
  cmp al, '0'
  jl invalid_dec_value
  cmp al, '9'
  jg invalid_dec_value
  sub al, 30h
  clc
  exit_ascii2dec:
  ret

  invalid_dec_value:
  stc
  jmp exit_ascii2dec

ascii2hex:
  cmp al, '0'
  jl invalid_hex_value
  cmp al, '9'
  jg check_if_letter
  sub al, 30h
  clc
  jmp exit_ascii2hex

  check_if_letter:
  cmp al, 'A'
  jl invalid_hex_value
  cmp al, 'F'
  jg check_if_lowercase_letter
  sub al, 37h
  clc
  jmp exit_ascii2hex

  check_if_lowercase_letter:
  cmp al, 'a'
  jl invalid_hex_value
  cmp al, 'f'
  jg invalid_hex_value
  sub al, 57h
  clc

  exit_ascii2hex:
  ret

  invalid_hex_value:
  stc
  jmp exit_ascii2hex


cmd_echo:
  mov si, input_buffer+5
  call skip_space
  call put_str_ln
  ret

cmd_restart:
  mov si, restart_msg
  call put_str
  mov cx, 3
  .print_dot:
    call sleep_1_sec
    mov ah, 0Eh
    mov al, '.'
    int 10h
  loop .print_dot

  int 19h
  ret

cmd_reverse:
  cld
  push di
  mov si, input_buffer + 7
  call skip_space
  cmp byte [si], 0
  je exit_cmd_reverse
  dec si
  mov di, si
  .find_end:
  inc si
  cmp byte [si], 0
  jne .find_end
  dec si

  mov ah, 0Eh
  .print_char:
  cmp di, si
  je exit_cmd_reverse

    mov al, byte[si]
    int 10h
    dec si
  jmp .print_char

  exit_cmd_reverse:
  pop di
  call new_line
  cld
  ret

cmd_cpuid:
  push bx
  push cx
  push dx

  call clear_output_buffer

  xor eax, eax
  cpuid
  mov [output_buffer], ebx
  mov [output_buffer+4], edx
  mov [output_buffer+8], ecx
  mov si, output_buffer
  call put_str_ln

  pop dx
  pop cx
  pop bx
  ret

cmd_hex2dec:
  push cx
  mov si, input_buffer+7
  call skip_space
  call strlen
  add si, cx
  dec si
  xor dx, dx
  mov ax, 1

  .accumulate:
  cmp cx, 0
  je quit_loop_1
  push ax ; push power
  xor ah, ah
  mov al, [si]
  call ascii2hex
  pop bx ; pop power
  push dx
  mul bx
  pop dx
  add dx, ax

  ; compute next power
  mov ax, bx
  mov bx, 10h ; (hex)
  push dx
  mul bx
  pop dx
  dec si
  loop .accumulate

  quit_loop_1:


  mov ax, dx
  call print_ax_dec
  call new_line

  pop cx
  ret

cmd_dec2hex:
  push cx
  mov si, input_buffer+7
  call skip_space
  call strlen
  add si, cx
  dec si
  xor dx, dx
  mov ax, 1

  .accumulate:
  cmp cx, 0
  je quit_loop
  push ax ; push power
  xor ah, ah
  mov al, [si]
  call ascii2dec
  pop bx ; pop power
  push dx
  mul bx
  pop dx
  add dx, ax

  ; compute next power
  mov ax, bx
  mov bx, 10 ; (decimal)
  push dx
  mul bx
  pop dx
  dec si
  loop .accumulate

  quit_loop:

  mov ax, dx
  call print_ax_hex
  call new_line
  pop cx
  ret

cmd_eval:
  ret

test_stack:
  mov ax, sp
  call print_ax_hex
  ret

kernel_start:

mov si, k_msg
call put_str_ln


read_command:
  mov ah, 0Eh
  mov al, '>'
  int 10h
  mov al, ' '
  int 10h

  call get_str_ln
  cmp byte [input_buffer], 0
  je read_command

  ; TODO handle leading spaces
  mov bx, commands
  mov cx, 7         ; set number of commands
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
  call put_str_ln

jmp read_command

cli
hlt

;** DATA **

k_msg db "Kernel loaded!", 0
restart_msg db "Restarting", 0
error_msg db "   Error!", 0
unknown_cmd_msg db "Unknown command!", 0
input_buffer times 128 db 0
output_buffer times 128 db 0
convert_buffer times 16 db 0

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



times 2048 - ($-$$) db 0 ; pad with zeros in order to fill the 1024 bytes

stack:
  times 256 db 0

times 2560 - ($-$$) db 0


